import AppKit
import FlutterMacOS
import Foundation

private enum MediaCommand {
  case play
  case pause
  case togglePlayPause
  case nextTrack
  case previousTrack
}

private enum AppleScriptPlayer: String, CaseIterable {
  case music
  case spotify

  var bundleIdentifier: String {
    switch self {
    case .music:
      return "com.apple.Music"
    case .spotify:
      return "com.spotify.client"
    }
  }
}

private final class CiderAPIClient {
  private let baseURL = URL(string: "http://127.0.0.1:10767/api/v1/playback")!
  private let bundleIdentifier = "sh.cider.genten.mac"
  private let statusQueue = DispatchQueue(label: "cc.koto.fluentLyrics.cider")
  private let freshStatusInterval: TimeInterval = 1.2
  private let staleStatusInterval: TimeInterval = 3.0
  private var cachedToken: String?
  private var suspendedUntil: Date?
  private var hasLoggedStatus = false
  private var isFetchingStatus = false
  private var lastStatus: [String: Any?]?
  private var lastSuccessAt: Date?
  private var pendingStatusCompletions: [([String: Any?]?) -> Void] = []

  var isRunning: Bool {
    !NSRunningApplication.runningApplications(
      withBundleIdentifier: bundleIdentifier
    ).isEmpty
  }

  func fetchStatus(completion: @escaping ([String: Any?]?) -> Void) {
    statusQueue.async {
      let now = Date()
      guard self.isRunning else {
        self.clearStatusCache()
        completion(nil)
        return
      }

      if let status = self.cachedStatus(maxAge: self.freshStatusInterval, now: now) {
        completion(status)
        return
      }

      if let suspendedUntil = self.suspendedUntil, now < suspendedUntil {
        completion(self.cachedStatus(maxAge: self.staleStatusInterval, now: now))
        return
      }

      guard let token = self.apiToken() else {
        self.logStatus("running but no API token found in Cider config")
        completion(self.cachedStatus(maxAge: self.staleStatusInterval, now: now))
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
      if let status = self.cachedStatus(maxAge: self.staleStatusInterval, now: now) {
        completion(status)
      } else {
        self.pendingStatusCompletions.append(completion)
      }

      self.getJSON(path: "now-playing", token: token) { [weak self] nowPlayingJSON in
        guard let self else {
          return
        }
        guard
          let nowPlayingJSON,
          let info = nowPlayingJSON["info"] as? [String: Any],
          !info.isEmpty
        else {
          self.completeStatusFetch(nil)
          return
        }

        self.getJSON(path: "is-playing", token: token) { isPlayingJSON in
          let isPlaying = isPlayingJSON?["is_playing"] as? Bool ?? false
          self.completeStatusFetch(self.statusMap(from: info, isPlaying: isPlaying))
        }
      }
    }
  }

  func send(command: MediaCommand, completion: @escaping (Bool) -> Void) {
    guard isRunning, let token = apiToken(), let path = path(for: command) else {
      completion(false)
      return
    }
    postJSON(path: path, token: token, body: nil, completion: completion)
  }

  func seek(toMilliseconds milliseconds: Double, completion: @escaping (Bool) -> Void) {
    guard isRunning, let token = apiToken() else {
      completion(false)
      return
    }
    postJSON(
      path: "seek",
      token: token,
      body: ["position": milliseconds / 1000],
      completion: completion
    )
  }

  private func path(for command: MediaCommand) -> String? {
    switch command {
    case .play:
      return "play"
    case .pause:
      return "pause"
    case .togglePlayPause:
      return "playpause"
    case .nextTrack:
      return "next"
    case .previousTrack:
      return "previous"
    }
  }

  private func statusMap(from info: [String: Any], isPlaying: Bool) -> [String: Any?] {
    let title = stringValue(info, keys: ["name", "title"]) ?? "Unknown Title"
    let artist = stringValue(info, keys: ["artistName", "artist"]) ?? "Unknown Artist"
    let album = stringValue(info, keys: ["albumName", "album"]) ?? "Unknown Album"
    let duration = numberValue(info, keys: ["durationInMillis"]) ?? 0
    let positionSeconds = numberValue(info, keys: ["currentPlaybackTime"]) ?? 0
    let artUrl = artworkURL(from: info) ?? "fallback"

    logStatus("received from Cider")

    return [
      "metadata": [
        "title": title,
        "artist": artist,
        "album": album,
        "duration": Int(duration),
        "artUrl": artUrl,
      ],
      "isPlaying": isPlaying,
      "position": Int(positionSeconds * 1000),
      "controlAbility": [
        "canPlayPause": true,
        "canGoNext": true,
        "canGoPrevious": true,
        "canSeek": true,
      ],
      "source": "cider",
    ]
  }

  private func artworkURL(from info: [String: Any]) -> String? {
    if let artUrl = stringValue(info, keys: ["artUrl", "artworkUrl"]), !artUrl.isEmpty {
      return artUrl
    }
    guard
      let artwork = info["artwork"] as? [String: Any],
      let url = artwork["url"] as? String,
      !url.isEmpty
    else {
      return nil
    }
    return url
  }

  private func getJSON(
    path: String,
    token: String,
    completion: @escaping ([String: Any]?) -> Void
  ) {
    request(path: path, token: token, method: "GET", body: nil, completion: completion)
  }

  private func postJSON(
    path: String,
    token: String,
    body: [String: Any]?,
    completion: @escaping (Bool) -> Void
  ) {
    request(path: path, token: token, method: "POST", body: body) { json in
      completion(json?["status"] as? String == "ok")
    }
  }

  private func request(
    path: String,
    token: String,
    method: String,
    body: [String: Any]?,
    completion: @escaping ([String: Any]?) -> Void
  ) {
    let url = baseURL.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.timeoutInterval = 0.8
    if !token.isEmpty {
      request.setValue(token, forHTTPHeaderField: "apptoken")
    }
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if let body {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
      guard
        error == nil,
        (response as? HTTPURLResponse)?.statusCode == 200,
        let data,
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      else {
        if (response as? HTTPURLResponse)?.statusCode == 403 {
          self.logStatus("Cider rejected API token")
        }
        completion(nil)
        return
      }
      completion(json)
    }.resume()
  }

  private func completeStatusFetch(_ status: [String: Any?]?) {
    statusQueue.async {
      let now = Date()
      if let status {
        self.lastStatus = status
        self.lastSuccessAt = now
        self.suspendedUntil = nil
      } else {
        self.suspendedUntil = now.addingTimeInterval(0.8)
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

    let elapsedMilliseconds = Int(now.timeIntervalSince(lastSuccessAt) * 1000)
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

  private func clearStatusCache() {
    let completions = pendingStatusCompletions
    lastStatus = nil
    lastSuccessAt = nil
    suspendedUntil = nil
    isFetchingStatus = false
    pendingStatusCompletions.removeAll()
    for completion in completions {
      completion(nil)
    }
  }

  private func apiToken() -> String? {
    if let cachedToken {
      return cachedToken
    }

    guard
      let configURL = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first?.appendingPathComponent("sh.cider.genten/spa-config.yml"),
      let config = try? String(contentsOf: configURL, encoding: .utf8)
    else {
      return nil
    }

    let lines = config.components(separatedBy: .newlines)
    var insideConnectivity = false
    var insideTokens = false
    var requiresToken = true

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if !line.hasPrefix(" ") && trimmed.hasSuffix(":") {
        insideConnectivity = trimmed == "connectivity:"
        insideTokens = false
        continue
      }
      guard insideConnectivity else {
        continue
      }
      if trimmed == "apiTokens:" {
        insideTokens = true
        continue
      }
      if trimmed.hasPrefix("apiTokensRequired:") {
        let value = trimmed
          .dropFirst("apiTokensRequired:".count)
          .trimmingCharacters(in: .whitespacesAndNewlines)
        requiresToken = value.lowercased() != "false"
      }
      if insideTokens {
        for prefix in ["token:", "- token:"] where trimmed.hasPrefix(prefix) {
          let token = trimmed
            .dropFirst(prefix.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
          if !token.isEmpty {
            cachedToken = token
            return token
          }
        }
      }
      if insideTokens, trimmed.hasSuffix(":"), !trimmed.hasPrefix("-") {
        insideTokens = false
      }
    }

    if !requiresToken {
      cachedToken = ""
      return ""
    }
    return nil
  }

  private func stringValue(_ dictionary: [String: Any], keys: [String]) -> String? {
    for key in keys {
      if let value = dictionary[key] as? String, !value.isEmpty {
        return value
      }
    }
    return nil
  }

  private func numberValue(_ dictionary: [String: Any], keys: [String]) -> Double? {
    for key in keys {
      if let value = dictionary[key] as? NSNumber {
        return value.doubleValue
      }
      if let value = dictionary[key] as? Double {
        return value
      }
      if let value = dictionary[key] as? Int {
        return Double(value)
      }
    }
    return nil
  }

  private func logStatus(_ message: String) {
    if hasLoggedStatus {
      return
    }
    hasLoggedStatus = true
    NSLog("FluentLyrics Cider status: %@", message)
  }
}

private final class MediaRemoteAppleScriptClient {
  private let statusQueue = DispatchQueue(label: "cc.koto.fluentLyrics.mediaRemoteAppleScript")
  private let freshStatusInterval: TimeInterval = 0.8
  private let staleStatusInterval: TimeInterval = 6.0
  private let delimiter = "|||FLUENT_LYRICS|||"
  private var hasLoggedFailureStatus = false
  private var hasLoggedSuccessfulStatus = false
  private var isFetchingStatus = false
  private var lastStatus: [String: Any?]?
  private var lastSuccessAt: Date?
  private var pendingStatusCompletions: [([String: Any?]?) -> Void] = []

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

      let status = self.fetchStatusWithAppleScript()
      self.completeStatusFetch(status)
    }
  }

  private func fetchStatusWithAppleScript() -> [String: Any?]? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", scriptSource]

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

    let timeout: TimeInterval = lastSuccessAt == nil ? 4.0 : 3.0
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

    return parseStatus(output)
  }

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

    logStatus("received from MediaRemote AppleScript")

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
        "canPlayPause": false,
        "canGoNext": false,
        "canGoPrevious": false,
        "canSeek": false,
      ],
      "source": "mediaremote",
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
    NSLog("FluentLyrics MediaRemote AppleScript status: %@", message)
  }

  private var scriptSource: String {
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
      set separator to "\(delimiter)"
      return titleValue & separator & artistValue & separator & albumValue & separator & (durationSeconds as text) & separator & (elapsedSeconds as text) & separator & (playbackRate as text) & separator & (isPlayingValue as text)
    end run
    """
  }
}

final class MacOSMediaService {
  private let ciderAPIClient = CiderAPIClient()
  private let mediaRemoteAppleScriptClient = MediaRemoteAppleScriptClient()
  private var hasLoggedAppleScriptStatus = false
  private var lastAppleScriptPlayer: AppleScriptPlayer?
  private var lastActiveStatusSource: String?

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getStatus":
      getStatus(result: result)
    case "play":
      result(send(.play))
    case "pause":
      result(send(.pause))
    case "playPause":
      result(send(.togglePlayPause))
    case "nextTrack":
      result(send(.nextTrack))
    case "previousTrack":
      result(send(.previousTrack))
    case "seek":
      guard
        let arguments = call.arguments as? [String: Any],
        let position = arguments["position"] as? NSNumber
      else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Position is null", details: nil))
        return
      }
      result(seek(toMilliseconds: position.doubleValue))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getStatus(result: @escaping FlutterResult) {
    ciderAPIClient.fetchStatus { ciderStatus in
      if let ciderStatus, self.isPlaying(ciderStatus) {
        DispatchQueue.main.async {
          self.rememberActiveStatus(ciderStatus)
          result(ciderStatus)
        }
        return
      }

      DispatchQueue.main.async {
        let appleScriptStatus = self.appleScriptStatus()
        if let appleScriptStatus, self.isPlaying(appleScriptStatus) {
          self.rememberActiveStatus(appleScriptStatus)
          result(appleScriptStatus)
          return
        }

        self.mediaRemoteAppleScriptClient.fetchStatus { mediaRemoteStatus in
          DispatchQueue.main.async {
            if let mediaRemoteStatus, self.isPlaying(mediaRemoteStatus) {
              self.rememberActiveStatus(mediaRemoteStatus)
              result(mediaRemoteStatus)
              return
            }

            result(
              self.preferredPausedStatus(from: [
                ciderStatus,
                appleScriptStatus,
                mediaRemoteStatus,
              ]) ?? ciderStatus ?? appleScriptStatus ?? mediaRemoteStatus
            )
          }
        }
      }
    }
  }

  private func isPlaying(_ status: [String: Any?]?) -> Bool {
    status?["isPlaying"] as? Bool == true
  }

  private func statusSource(_ status: [String: Any?]?) -> String? {
    status?["source"] as? String
  }

  private func rememberActiveStatus(_ status: [String: Any?]?) {
    guard let source = statusSource(status) else {
      return
    }
    lastActiveStatusSource = source
  }

  private func preferredPausedStatus(from statuses: [[String: Any?]?]) -> [String: Any?]? {
    guard let lastActiveStatusSource else {
      return nil
    }
    for status in statuses where statusSource(status) == lastActiveStatusSource {
      return status
    }
    return nil
  }

  private func logAppleScriptStatus(_ message: String) {
    if hasLoggedAppleScriptStatus {
      return
    }
    hasLoggedAppleScriptStatus = true
    NSLog("FluentLyrics AppleScript status: %@", message)
  }

  private func send(_ command: MediaCommand) -> Bool {
    let semaphore = DispatchSemaphore(value: 0)
    var didSendWithCider = false
    ciderAPIClient.send(command: command) { success in
      didSendWithCider = success
      semaphore.signal()
    }
    if semaphore.wait(timeout: .now() + 0.9) == .success, didSendWithCider {
      return true
    }

    if controlWithAppleScript(command) {
      return true
    }

    return false
  }

  private func seek(toMilliseconds milliseconds: Double) -> Bool {
    let semaphore = DispatchSemaphore(value: 0)
    var didSeekWithCider = false
    ciderAPIClient.seek(toMilliseconds: milliseconds) { success in
      didSeekWithCider = success
      semaphore.signal()
    }
    if semaphore.wait(timeout: .now() + 0.9) == .success, didSeekWithCider {
      return true
    }

    if seekWithAppleScript(toMilliseconds: milliseconds) {
      return true
    }

    return false
  }

  private func appleScriptStatus() -> [String: Any?]? {
    var firstPausedStatus: [String: Any?]?
    var firstPausedPlayer: AppleScriptPlayer?
    var lastActivePausedStatus: [String: Any?]?

    for player in AppleScriptPlayer.allCases {
      guard isRunning(player) else {
        continue
      }
      guard let status = appleScriptStatus(for: player) else {
        continue
      }

      if status["isPlaying"] as? Bool == true {
        lastAppleScriptPlayer = player
        logAppleScriptStatus("received from \(player.rawValue)")
        return status
      }

      if firstPausedStatus == nil {
        firstPausedStatus = status
        firstPausedPlayer = player
      }

      if player == lastAppleScriptPlayer {
        lastActivePausedStatus = status
      }
    }

    if let lastActivePausedStatus, let lastAppleScriptPlayer {
      logAppleScriptStatus("received paused track from \(lastAppleScriptPlayer.rawValue)")
      return lastActivePausedStatus
    }

    if let firstPausedStatus, let firstPausedPlayer {
      lastAppleScriptPlayer = firstPausedPlayer
      logAppleScriptStatus("received paused track from \(firstPausedPlayer.rawValue)")
      return firstPausedStatus
    }

    lastAppleScriptPlayer = nil
    logAppleScriptStatus("empty")
    return nil
  }

  private func appleScriptStatus(for player: AppleScriptPlayer) -> [String: Any?]? {
    switch player {
    case .music:
      return parseAppleScriptStatus(
        runAppleScript("""
        tell application "Music"
          if player state is stopped then return ""
          set trackName to name of current track
          set artistName to artist of current track
          set albumName to album of current track
          set durationSeconds to duration of current track
          set positionSeconds to player position
          set stateName to player state as string
          return trackName & linefeed & artistName & linefeed & albumName & linefeed & (durationSeconds as text) & linefeed & (positionSeconds as text) & linefeed & stateName & linefeed & "fallback"
        end tell
        """),
        durationMultiplier: 1000,
        player: player
      )
    case .spotify:
      return parseAppleScriptStatus(
        runAppleScript("""
        tell application "Spotify"
          if player state is stopped then return ""
          set trackName to name of current track
          set artistName to artist of current track
          set albumName to album of current track
          set durationMilliseconds to duration of current track
          set positionSeconds to player position
          set stateName to player state as string
          set artURL to artwork url of current track
          return trackName & linefeed & artistName & linefeed & albumName & linefeed & (durationMilliseconds as text) & linefeed & (positionSeconds as text) & linefeed & stateName & linefeed & artURL
        end tell
        """),
        durationMultiplier: 1,
        player: player
      )
    }
  }

  private func parseAppleScriptStatus(
    _ output: String?,
    durationMultiplier: Double,
    player: AppleScriptPlayer
  ) -> [String: Any?]? {
    guard let output, !output.isEmpty else {
      return nil
    }

    let lines = output.components(separatedBy: .newlines)
    guard lines.count >= 6 else {
      return nil
    }

    let durationValue = Double(lines[3]) ?? 0
    let positionValue = Double(lines[4]) ?? 0
    let artUrl = lines.count >= 7 && !lines[6].isEmpty ? lines[6] : "fallback"

    return [
      "metadata": [
        "title": lines[0].isEmpty ? "Unknown Title" : lines[0],
        "artist": lines[1].isEmpty ? "Unknown Artist" : lines[1],
        "album": lines[2].isEmpty ? "Unknown Album" : lines[2],
        "duration": Int(durationValue * durationMultiplier),
        "artUrl": artUrl,
      ],
      "isPlaying": lines[5].lowercased() == "playing",
      "position": Int(positionValue * 1000),
      "controlAbility": [
        "canPlayPause": true,
        "canGoNext": true,
        "canGoPrevious": true,
        "canSeek": true,
      ],
      "source": player.rawValue,
    ]
  }

  private func controlWithAppleScript(_ command: MediaCommand) -> Bool {
    let players = orderedAppleScriptPlayers()
    for player in players where isRunning(player) {
      let scriptCommand: String
      switch command {
      case .play:
        scriptCommand = "play"
      case .pause:
        scriptCommand = "pause"
      case .togglePlayPause:
        scriptCommand = "playpause"
      case .nextTrack:
        scriptCommand = "next track"
      case .previousTrack:
        scriptCommand = "previous track"
      }

      if runAppleScriptCommand("""
      tell application "\(applicationName(for: player))"
        \(scriptCommand)
      end tell
      """) {
        lastAppleScriptPlayer = player
        return true
      }
    }
    return false
  }

  private func seekWithAppleScript(toMilliseconds milliseconds: Double) -> Bool {
    let seconds = String(format: "%.3f", milliseconds / 1000)
    let players = orderedAppleScriptPlayers()
    for player in players where isRunning(player) {
      if runAppleScriptCommand("""
      tell application "\(applicationName(for: player))"
        set player position to \(seconds)
      end tell
      """) {
        lastAppleScriptPlayer = player
        return true
      }
    }
    return false
  }

  private func orderedAppleScriptPlayers() -> [AppleScriptPlayer] {
    var players: [AppleScriptPlayer] = []
    if let lastAppleScriptPlayer {
      players.append(lastAppleScriptPlayer)
    }
    for player in AppleScriptPlayer.allCases where !players.contains(player) {
      players.append(player)
    }
    return players
  }

  private func applicationName(for player: AppleScriptPlayer) -> String {
    switch player {
    case .music:
      return "Music"
    case .spotify:
      return "Spotify"
    }
  }

  private func isRunning(_ player: AppleScriptPlayer) -> Bool {
    !NSRunningApplication.runningApplications(
      withBundleIdentifier: player.bundleIdentifier
    ).isEmpty
  }

  private func runAppleScript(_ source: String) -> String? {
    var error: NSDictionary?
    let descriptor = NSAppleScript(source: source)?.executeAndReturnError(&error)
    if error != nil {
      return nil
    }
    return descriptor?.stringValue
  }

  private func runAppleScriptCommand(_ source: String) -> Bool {
    var error: NSDictionary?
    NSAppleScript(source: source)?.executeAndReturnError(&error)
    return error == nil
  }

}
