import AppKit
import FlutterMacOS
import Foundation

private enum MediaCommand {
  case play
  case pause
  case togglePlayPause
  case nextTrack
  case previousTrack

  var mediaRemoteCommand: Int {
    switch self {
    case .play:
      return 0
    case .pause:
      return 1
    case .togglePlayPause:
      return 2
    case .nextTrack:
      return 4
    case .previousTrack:
      return 5
    }
  }
}

private struct MediaRemoteAdapterPaths {
  let script: URL
  let framework: URL
  let testClient: URL?

  static func resolve() -> MediaRemoteAdapterPaths? {
    let fileManager = FileManager.default
    let resourceURL = Bundle.main.resourceURL

    let scriptCandidates = [
      resourceURL?.appendingPathComponent("mediaremote-adapter.pl"),
      resourceURL?.appendingPathComponent("MediaRemoteAdapter/mediaremote-adapter.pl"),
    ].compactMap { $0 }

    let frameworkCandidates = [
      Bundle.main.privateFrameworksURL?.appendingPathComponent("MediaRemoteAdapter.framework"),
      resourceURL?.appendingPathComponent("MediaRemoteAdapter.framework"),
      resourceURL?.appendingPathComponent("MediaRemoteAdapter/MediaRemoteAdapter.framework"),
    ].compactMap { $0 }

    guard
      let script = scriptCandidates.first(where: { fileManager.fileExists(atPath: $0.path) }),
      let framework = frameworkCandidates.first(where: { fileManager.fileExists(atPath: $0.path) })
    else {
      return nil
    }

    let helperCandidates = [
      resourceURL?.appendingPathComponent("MediaRemoteAdapterTestClient"),
      resourceURL?.appendingPathComponent("MediaRemoteAdapter/MediaRemoteAdapterTestClient"),
    ].compactMap { $0 }
    let helper = helperCandidates.first(where: { fileManager.fileExists(atPath: $0.path) })

    return MediaRemoteAdapterPaths(script: script, framework: framework, testClient: helper)
  }
}

private final class MediaRemoteAdapterClient {
  private let commandQueue = DispatchQueue(label: "cc.koto.fluentLyrics.mediaRemoteAdapterCommand")
  private let streamQueue = DispatchQueue(label: "cc.koto.fluentLyrics.mediaRemoteAdapterStream")
  private var streamProcess: Process?
  private var streamOutputPipe: Pipe?
  private var streamBuffer = Data()
  private var currentPayload: [String: Any] = [:]
  private var latestStatus: [String: Any]?
  private var hasLoggedMissingAdapter = false

  var isAvailable: Bool {
    MediaRemoteAdapterPaths.resolve() != nil
  }

  func latestStatusSnapshot() -> [String: Any]? {
    streamQueue.sync {
      latestStatus
    }
  }

  func startStreaming(
    onStatus: @escaping ([String: Any]?) -> Void,
    onFailure: @escaping (String) -> Void
  ) -> Bool {
    guard let paths = MediaRemoteAdapterPaths.resolve() else {
      logMissingAdapterOnce()
      return false
    }

    var didStart = false
    streamQueue.sync {
      if streamProcess != nil {
        didStart = true
        return
      }

      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
      process.arguments = perlArguments(
        paths: paths,
        command: ["stream", "--micros", "--debounce=100"]
      )

      let outputPipe = Pipe()
      process.standardOutput = outputPipe
      process.standardError = FileHandle.nullDevice

      outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
        let data = handle.availableData
        if data.isEmpty { return }
        self?.streamQueue.async {
          self?.consumeStreamData(data, onStatus: onStatus)
        }
      }

      process.terminationHandler = { [weak self] process in
        outputPipe.fileHandleForReading.readabilityHandler = nil
        self?.streamQueue.async {
          self?.streamProcess = nil
          self?.streamOutputPipe = nil
          self?.streamBuffer.removeAll()
          if process.terminationStatus != 0 {
            onFailure("mediaremote-adapter stream exited with \(process.terminationStatus)")
          }
        }
      }

      do {
        try process.run()
        streamProcess = process
        streamOutputPipe = outputPipe
        didStart = true
      } catch {
        outputPipe.fileHandleForReading.readabilityHandler = nil
        onFailure("failed to start mediaremote-adapter stream: \(error)")
      }
    }

    return didStart
  }

  func stopStreaming() {
    streamQueue.sync {
      streamOutputPipe?.fileHandleForReading.readabilityHandler = nil
      streamOutputPipe = nil
      streamBuffer.removeAll()
      guard let process = streamProcess else { return }
      streamProcess = nil
      if process.isRunning {
        process.terminate()
      }
    }
  }

  func fetchStatus(completion: @escaping ([String: Any]?) -> Void) {
    commandQueue.async {
      guard
        let output = self.runAdapterCommand(
          ["get", "--micros", "--no-artwork"],
          timeout: 3.0
        )
      else {
        completion(nil)
        return
      }

      completion(self.parseGetOutput(output))
    }
  }

  func send(command: MediaCommand, completion: @escaping (Bool) -> Void) {
    commandQueue.async {
      let success = self.runAdapterCommand(
        ["send", "\(command.mediaRemoteCommand)"],
        timeout: 4.0
      ) != nil
      completion(success)
    }
  }

  func seek(positionMilliseconds: Int, completion: @escaping (Bool) -> Void) {
    commandQueue.async {
      let success = self.runAdapterCommand(
        ["seek", "\(positionMilliseconds * 1000)"],
        timeout: 4.0
      ) != nil
      completion(success)
    }
  }

  private func consumeStreamData(
    _ data: Data,
    onStatus: @escaping ([String: Any]?) -> Void
  ) {
    streamBuffer.append(data)
    let newline = Data([0x0A])

    while let range = streamBuffer.firstRange(of: newline) {
      let lineData = streamBuffer.subdata(in: 0..<range.lowerBound)
      streamBuffer.removeSubrange(0..<range.upperBound)
      guard
        !lineData.isEmpty,
        let line = String(data: lineData, encoding: .utf8)
      else {
        continue
      }

      let status = parseStreamLine(line)
      latestStatus = status
      onStatus(status)
    }
  }

  private func parseStreamLine(_ line: String) -> [String: Any]? {
    guard
      let data = line.data(using: .utf8),
      let object = try? JSONSerialization.jsonObject(with: data),
      let event = object as? [String: Any],
      let payload = event["payload"] as? [String: Any]
    else {
      return nil
    }

    let isDiff = boolValue(event["diff"]) ?? false
    if isDiff {
      let elapsedTimeChanged =
        payload["elapsedTimeMicros"] != nil ||
        payload["elapsedTime"] != nil ||
        payload["elapsedTimeNowMicros"] != nil
      let timestampChanged =
        payload["timestampEpochMicros"] != nil ||
        payload["timestamp"] != nil

      for (key, value) in payload {
        if value is NSNull {
          currentPayload.removeValue(forKey: key)
        } else {
          currentPayload[key] = value
        }
      }

      if elapsedTimeChanged && !timestampChanged {
        // Keep elapsed/timestamp pairs coherent when diff events split them.
        currentPayload["timestampEpochMicros"] = Int64(
          Date().timeIntervalSince1970 * 1_000_000
        )
      }
    } else {
      currentPayload = payload.filter { !($0.value is NSNull) }
    }

    return convertAdapterPayload(currentPayload, event: "adapterStream")
  }

  private func parseGetOutput(_ output: String) -> [String: Any]? {
    guard
      let data = output.data(using: .utf8),
      let object = try? JSONSerialization.jsonObject(with: data),
      !(object is NSNull),
      let payload = object as? [String: Any]
    else {
      return nil
    }

    return convertAdapterPayload(payload, event: nil)
  }

  private func convertAdapterPayload(_ payload: [String: Any], event: String?) -> [String: Any]? {
    guard
      let title = stringValue(payload["title"]),
      !title.isEmpty
    else {
      return nil
    }

    let artist = stringValue(payload["artist"]) ?? "Unknown Artist"
    let album = stringValue(payload["album"]) ?? "Unknown Album"
    let durationMs = durationMilliseconds(payload)
    let positionMs = positionMilliseconds(payload, durationMs: durationMs)
    let isPlaying = boolValue(payload["playing"]) ?? false

    var artUrl = "fallback"
    if
      let artworkData = stringValue(payload["artworkData"]),
      !artworkData.isEmpty
    {
      let mimeType = stringValue(payload["artworkMimeType"]) ?? "image/jpeg"
      artUrl = "data:\(mimeType);base64,\(artworkData)"
    }

    let prohibitsSkip = boolValue(payload["prohibitsSkip"]) ?? false
    var status: [String: Any] = [
      "metadata": [
        "title": title,
        "artist": artist,
        "album": album,
        "duration": durationMs,
        "artUrl": artUrl,
      ],
      "isPlaying": isPlaying,
      "position": positionMs,
      "controlAbility": [
        "canPlayPause": true,
        "canGoNext": !prohibitsSkip,
        "canGoPrevious": true,
        "canSeek": durationMs > 0,
      ],
      "source": "mediaremote-adapter",
    ]
    if let event {
      status["event"] = event
    }
    if let bundleIdentifier = stringValue(payload["bundleIdentifier"]) {
      status["sourceApp"] = bundleIdentifier
    }
    return status
  }

  private func durationMilliseconds(_ payload: [String: Any]) -> Int {
    if let durationMicros = int64Value(payload["durationMicros"]) {
      return Int(durationMicros / 1000)
    }
    if let durationSeconds = doubleValue(payload["duration"]) {
      return Int(durationSeconds * 1000)
    }
    return 0
  }

  private func positionMilliseconds(_ payload: [String: Any], durationMs: Int) -> Int {
    var elapsedMicros =
      int64Value(payload["elapsedTimeNowMicros"]) ??
      int64Value(payload["elapsedTimeMicros"]) ??
      Int64((doubleValue(payload["elapsedTime"]) ?? 0) * 1_000_000)

    if
      payload["elapsedTimeNowMicros"] == nil,
      boolValue(payload["playing"]) == true,
      let timestampMicros = int64Value(payload["timestampEpochMicros"])
    {
      let nowMicros = Int64(Date().timeIntervalSince1970 * 1_000_000)
      let playbackRate = doubleValue(payload["playbackRate"]) ?? 1.0
      let delta = Int64(Double(nowMicros - timestampMicros) * playbackRate)
      if delta > 0 {
        elapsedMicros += delta
      }
    }

    var positionMs = Int(elapsedMicros / 1000)
    if durationMs > 0 {
      positionMs = min(positionMs, durationMs)
    }
    return max(positionMs, 0)
  }

  private func runAdapterCommand(_ command: [String], timeout: TimeInterval) -> String? {
    guard let paths = MediaRemoteAdapterPaths.resolve() else {
      logMissingAdapterOnce()
      return nil
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
    process.arguments = perlArguments(paths: paths, command: command)

    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = FileHandle.nullDevice

    let semaphore = DispatchSemaphore(value: 0)
    process.terminationHandler = { _ in
      semaphore.signal()
    }

    do {
      try process.run()
    } catch {
      NSLog("FluentLyrics mediaremote-adapter failed to run: %@", "\(error)")
      return nil
    }

    if semaphore.wait(timeout: .now() + timeout) == .timedOut {
      process.terminate()
      NSLog("FluentLyrics mediaremote-adapter timed out for command: %@", command.joined(separator: " "))
      return nil
    }

    guard process.terminationStatus == 0 else {
      return nil
    }

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: outputData, encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  private func perlArguments(paths: MediaRemoteAdapterPaths, command: [String]) -> [String] {
    var arguments = [paths.script.path, paths.framework.path]
    if let testClient = paths.testClient {
      arguments.append(testClient.path)
    }
    arguments.append(contentsOf: command)
    return arguments
  }

  private func logMissingAdapterOnce() {
    guard !hasLoggedMissingAdapter else { return }
    hasLoggedMissingAdapter = true
    NSLog(
      "FluentLyrics mediaremote-adapter is not bundled; macOS media integration is unavailable"
    )
  }
}

final class MacOSMediaService: NSObject, FlutterStreamHandler {
  private let adapterClient = MediaRemoteAdapterClient()
  private var eventSink: FlutterEventSink?

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getStatus":
      getStatus(result: result)
    case "play":
      send(.play, result: result)
    case "pause":
      send(.pause, result: result)
    case "playPause":
      send(.togglePlayPause, result: result)
    case "nextTrack":
      send(.nextTrack, result: result)
    case "previousTrack":
      send(.previousTrack, result: result)
    case "seek":
      seek(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    _ = adapterClient.startStreaming(
      onStatus: { [weak self] status in
        DispatchQueue.main.async {
          guard self?.eventSink != nil else { return }
          _ = events(status)
        }
      },
      onFailure: { error in
        DispatchQueue.main.async {
          _ = events(
            FlutterError(
              code: "MEDIAREMOTE_ADAPTER_STREAM_FAILED",
              message: error,
              details: nil
            )
          )
        }
      }
    )
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    adapterClient.stopStreaming()
    return nil
  }

  private func getStatus(result: @escaping FlutterResult) {
    adapterClient.fetchStatus { status in
      DispatchQueue.main.async {
        result(status)
      }
    }
  }

  private func send(_ command: MediaCommand, result: @escaping FlutterResult) {
    adapterClient.send(command: command) { success in
      DispatchQueue.main.async {
        result(success)
      }
    }
  }

  private func seek(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let position = arguments["position"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENT",
          message: "Position is missing",
          details: nil
        )
      )
      return
    }

    adapterClient.seek(positionMilliseconds: position) { success in
      DispatchQueue.main.async {
        result(success)
      }
    }
  }
}

private func stringValue(_ value: Any?) -> String? {
  if let string = value as? String {
    return string
  }
  if let number = value as? NSNumber {
    return number.stringValue
  }
  return nil
}

private func boolValue(_ value: Any?) -> Bool? {
  if let bool = value as? Bool {
    return bool
  }
  if let number = value as? NSNumber {
    return number.boolValue
  }
  if let string = value as? String {
    let lowered = string.lowercased()
    if lowered == "true" { return true }
    if lowered == "false" { return false }
  }
  return nil
}

private func int64Value(_ value: Any?) -> Int64? {
  if let int = value as? Int {
    return Int64(int)
  }
  if let int64 = value as? Int64 {
    return int64
  }
  if let number = value as? NSNumber {
    return number.int64Value
  }
  if let string = value as? String {
    return Int64(string)
  }
  return nil
}

private func doubleValue(_ value: Any?) -> Double? {
  if let number = value as? NSNumber {
    return number.doubleValue
  }
  if let string = value as? String {
    return Double(string)
  }
  return nil
}
