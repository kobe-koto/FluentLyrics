import AppKit
import FlutterMacOS
import Foundation

// Media integration backed exclusively by the system-wide Now Playing session
// (the private MediaRemote framework). Since macOS 15.4, mediaremoted denies
// direct in-process MediaRemote access to unentitled apps, so both reads and
// commands are routed through /usr/bin/osascript (an entitled Apple binary)
// using AppleScriptObjC to reach the framework's Objective-C classes:
//   - MRNowPlayingRequest.localNowPlayingItem() for metadata/playback state
//   - MRNowPlayingController.localRouteController().sendCommand(_:options:)
//     for transport controls (play/pause/next/previous)
// Seeking is not exposed through these classes, so canSeek is reported false.
private enum MediaCommand {
  case play
  case pause
  case togglePlayPause
  case nextTrack
  case previousTrack

  // MRMediaRemoteCommand values understood by MRNowPlayingController.
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

private final class NowPlayingClient {
  private let statusQueue = DispatchQueue(label: "cc.koto.fluentLyrics.nowPlayingStatus")
  private let commandQueue = DispatchQueue(label: "cc.koto.fluentLyrics.nowPlayingCommand")
  private let freshStatusInterval: TimeInterval = 0.8
  private let staleStatusInterval: TimeInterval = 6.0
  private let delimiter = "|||FLUENT_LYRICS|||"
  private var hasLoggedFailureStatus = false
  private var hasLoggedSuccessfulStatus = false
  private var isFetchingStatus = false
  private var lastStatus: [String: Any?]?
  private var lastSuccessAt: Date?
  private var pendingStatusCompletions: [([String: Any?]?) -> Void] = []

  // MARK: - Status

  func fetchStatus(completion: @escaping ([String: Any?]?) -> Void) {
    statusQueue.async {
      let now = Date()
      if let status = self.cachedStatus(maxAge: self.freshStatusInterval, now: now) {
        completion(status)
        return
      }

      if self.isFetchingStatus {
        if let status = self.cachedStatus(maxAge: self.staleStatusInterval, now: now) {
          completion(status)
        } else {
          self.pendingStatusCompletions.append(completion)
        }
        return
      }

      self.isFetchingStatus = true
      self.pendingStatusCompletions.append(completion)

      let status = self.runStatusScript()
      self.completeStatusFetch(status)
    }
  }

  // MARK: - Commands

  func send(command: MediaCommand, completion: @escaping (Bool) -> Void) {
    commandQueue.async {
      let output = self.runOSAScript(
        source: self.commandScriptSource(for: command),
        timeout: 4.0
      )
      let didSend = output == "ok"
      if didSend {
        self.invalidateStatusCache()
      } else {
        self.logStatus("command \(command.mediaRemoteCommand) failed", isFailure: true)
      }
      completion(didSend)
    }
  }

  // Drop the cached status after a command so the next poll reflects the new
  // playback state instead of a pre-command snapshot.
  private func invalidateStatusCache() {
    statusQueue.async {
      self.lastStatus = nil
      self.lastSuccessAt = nil
    }
  }

  // MARK: - osascript execution

  private func runStatusScript() -> [String: Any?]? {
    let timeout: TimeInterval = lastSuccessAt == nil ? 4.0 : 3.0
    guard let output = runOSAScript(source: statusScriptSource, timeout: timeout) else {
      return nil
    }
    return parseStatus(output)
  }

  private func runOSAScript(source: String, timeout: TimeInterval) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", source]

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
      logStatus("failed to run osascript", isFailure: true)
      return nil
    }

    if semaphore.wait(timeout: .now() + timeout) == .timedOut {
      process.terminate()
      logStatus("osascript timed out", isFailure: true)
      return nil
    }

    guard process.terminationStatus == 0 else {
      logStatus("osascript exited with \(process.terminationStatus)", isFailure: true)
      return nil
    }

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    guard
      let output = String(data: outputData, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      !output.isEmpty
    else {
      return nil
    }
    return output
  }

  // MARK: - Parsing and caching

  private func parseStatus(_ output: String) -> [String: Any?]? {
    let parts = output.components(separatedBy: delimiter)
    guard parts.count >= 7 else {
      return nil
    }

    let title = parts[0].isEmpty ? "Unknown Title" : parts[0]
    let artist = parts[1].isEmpty ? "Unknown Artist" : parts[1]
    let album = parts[2].isEmpty ? "Unknown Album" : parts[2]
    let durationSeconds = Double(parts[3]) ?? 0
    let elapsedSeconds = Double(parts[4]) ?? 0
    let playbackRate = Double(parts[5]) ?? 0
    let isPlaying = parts[6].lowercased() == "true" || (Double(parts[6]) ?? 0) != 0
    let sourceApp = parts.count >= 8 ? parts[7] : ""

    logStatus("received from Now Playing")

    return [
      "metadata": [
        "title": title,
        "artist": artist,
        "album": album,
        "duration": Int(durationSeconds * 1000),
        "artUrl": "fallback",
      ],
      "isPlaying": isPlaying,
      "position": Int(elapsedSeconds * 1000),
      "controlAbility": [
        "canPlayPause": true,
        "canGoNext": true,
        "canGoPrevious": true,
        "canSeek": false,
      ],
      "source": "mediaremote",
      "sourceApp": sourceApp,
      "playbackRate": playbackRate,
    ]
  }

  private func completeStatusFetch(_ status: [String: Any?]?) {
    statusQueue.async {
      let now = Date()
      if let status {
        self.lastStatus = status
        self.lastSuccessAt = now
      }

      let resolvedStatus = status ?? self.cachedStatus(maxAge: self.staleStatusInterval, now: now)
      let completions = self.pendingStatusCompletions
      self.pendingStatusCompletions.removeAll()
      self.isFetchingStatus = false
      for completion in completions {
        completion(resolvedStatus)
      }
    }
  }

  private func cachedStatus(maxAge: TimeInterval, now: Date) -> [String: Any?]? {
    guard
      let lastStatus,
      let lastSuccessAt,
      now.timeIntervalSince(lastSuccessAt) <= maxAge
    else {
      return nil
    }

    var status = lastStatus
    guard
      status["isPlaying"] as? Bool == true,
      let position = status["position"] as? Int
    else {
      return status
    }

    let playbackRate = status["playbackRate"] as? Double ?? 1
    let elapsedMilliseconds = Int(now.timeIntervalSince(lastSuccessAt) * 1000 * playbackRate)
    var advancedPosition = position + elapsedMilliseconds
    if
      let metadata = status["metadata"] as? [String: Any?],
      let duration = metadata["duration"] as? Int,
      duration > 0
    {
      advancedPosition = min(advancedPosition, duration)
    }
    status["position"] = advancedPosition
    return status
  }

  private func logStatus(_ message: String, isFailure: Bool = false) {
    if isFailure {
      if hasLoggedFailureStatus {
        return
      }
      hasLoggedFailureStatus = true
    } else {
      if hasLoggedSuccessfulStatus {
        return
      }
      hasLoggedSuccessfulStatus = true
    }
    NSLog("FluentLyrics Now Playing status: %@", message)
  }

  // MARK: - AppleScript sources

  private var statusScriptSource: String {
    """
    use framework "AppKit"

    on textValue(v, fallbackValue)
      if v is missing value then return fallbackValue
      set t to v as text
      if t is "" then return fallbackValue
      return t
    end textValue

    on numberValue(v, fallbackValue)
      if v is missing value then return fallbackValue
      try
        return v as real
      on error
        return fallbackValue
      end try
    end numberValue

    on run
      set MediaRemote to current application's NSBundle's bundleWithPath:"/System/Library/PrivateFrameworks/MediaRemote.framework/"
      MediaRemote's load()
      set MRNowPlayingRequest to current application's NSClassFromString("MRNowPlayingRequest")
      if MRNowPlayingRequest is missing value then return ""
      set currentItem to MRNowPlayingRequest's localNowPlayingItem()
      if currentItem is missing value then return ""
      set infoDict to currentItem's nowPlayingInfo()
      if infoDict is missing value then return ""
      set titleValue to my textValue(infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoTitle", "Unknown Title")
      set artistValue to my textValue(infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoArtist", "Unknown Artist")
      set albumValue to my textValue(infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoAlbum", "Unknown Album")
      set durationSeconds to my numberValue(infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoDuration", 0)
      set elapsedSeconds to my numberValue(infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoElapsedTime", 0)
      set playbackRate to my numberValue(infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoPlaybackRate", 0)
      set isPlayingValue to false
      if playbackRate is not 0 then set isPlayingValue to true
      set timestampValue to infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoTimestamp"
      if isPlayingValue and timestampValue is not missing value then
        set nowDate to current application's NSDate's |date|()
        set elapsedSeconds to elapsedSeconds + (((nowDate's timeIntervalSinceDate:timestampValue) as real) * playbackRate)
      end if
      if durationSeconds > 0 and elapsedSeconds > durationSeconds then set elapsedSeconds to durationSeconds
      if elapsedSeconds < 0 then set elapsedSeconds to 0
      set appNameValue to ""
      try
        set playerPath to MRNowPlayingRequest's localNowPlayingPlayerPath()
        if playerPath is not missing value then
          set appNameValue to my textValue(playerPath's client()'s displayName(), "")
        end if
      end try
      set separator to "\(delimiter)"
      return titleValue & separator & artistValue & separator & albumValue & separator & (durationSeconds as text) & separator & (elapsedSeconds as text) & separator & (playbackRate as text) & separator & (isPlayingValue as text) & separator & appNameValue
    end run
    """
  }

  private func commandScriptSource(for command: MediaCommand) -> String {
    """
    use framework "AppKit"

    on run
      set MediaRemote to current application's NSBundle's bundleWithPath:"/System/Library/PrivateFrameworks/MediaRemote.framework/"
      MediaRemote's load()
      set MRNowPlayingController to current application's NSClassFromString("MRNowPlayingController")
      if MRNowPlayingController is missing value then return "unavailable"
      set controller to MRNowPlayingController's localRouteController()
      if controller is missing value then return "unavailable"
      set commandOptions to current application's NSDictionary's alloc()'s init()
      controller's sendCommand:\(command.mediaRemoteCommand) options:commandOptions completion:(missing value)
      -- Give the asynchronous XPC send a moment to be delivered before the
      -- osascript process exits, otherwise the command can be dropped.
      delay 0.2
      return "ok"
    end run
    """
  }
}

final class MacOSMediaService {
  private let nowPlayingClient = NowPlayingClient()

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
      // Seeking is not supported through the Now Playing command bridge.
      result(false)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getStatus(result: @escaping FlutterResult) {
    nowPlayingClient.fetchStatus { status in
      DispatchQueue.main.async {
        result(status)
      }
    }
  }

  private func send(_ command: MediaCommand, result: @escaping FlutterResult) {
    nowPlayingClient.send(command: command) { success in
      DispatchQueue.main.async {
        result(success)
      }
    }
  }
}
