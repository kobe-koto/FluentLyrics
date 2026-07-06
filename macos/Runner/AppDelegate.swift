import Cocoa
import Darwin
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private static let showMainWindowNotification =
    Notification.Name("cc.koto.fluentLyrics.showMainWindow")

  override func applicationWillFinishLaunching(_ notification: Notification) {
    prepareSingleInstanceStartup()
    super.applicationWillFinishLaunching(notification)
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    DistributedNotificationCenter.default().addObserver(
      self,
      selector: #selector(showMainWindowFromInstanceRequest(_:)),
      name: Self.showMainWindowNotification,
      object: nil
    )
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    DistributedNotificationCenter.default().removeObserver(self)
  }

  private func prepareSingleInstanceStartup() {
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
      failStartup("Failed to resolve bundle identifier.")
    }
    guard let currentExecutableURL = Bundle.main.executableURL else {
      failStartup("Failed to resolve current executable.")
    }
    guard let currentIdentity = FileIdentity(url: currentExecutableURL) else {
      failStartup("Failed to inspect current executable.")
    }

    let currentPID = ProcessInfo.processInfo.processIdentifier
    let currentUID = getuid()
    let existingApps = NSRunningApplication
      .runningApplications(withBundleIdentifier: bundleIdentifier)
      .filter {
        $0.processIdentifier != currentPID &&
          processUID(for: $0.processIdentifier) == currentUID
      }

    if let sameExecutable = existingApps.first(where: {
      guard let executableURL = $0.executableURL,
            let identity = FileIdentity(url: executableURL) else {
        return false
      }
      return identity == currentIdentity
    }) {
      requestMainWindowFocus(for: sameExecutable)
      exit(0)
    }

    // If a newer version is already running, defer to it: focus the running
    // instance and exit without terminating it. This prevents an older build
    // from replacing a newer one that a user already launched.
    if let currentVersion = currentVersion,
       let newerApp = newestApp(among: existingApps, newerThan: currentVersion) {
      requestMainWindowFocus(for: newerApp)
      exit(0)
    }

    for app in existingApps {
      guard terminate(app: app) else {
        failStartup(
          "Failed to terminate existing Fluent Lyrics process \(app.processIdentifier)."
        )
      }
    }
  }

  private func requestMainWindowFocus(for app: NSRunningApplication) {
    DistributedNotificationCenter.default().postNotificationName(
      Self.showMainWindowNotification,
      object: nil,
      userInfo: ["senderPID": ProcessInfo.processInfo.processIdentifier],
      deliverImmediately: true
    )
    app.activate(options: [.activateIgnoringOtherApps])
  }

  private func terminate(app: NSRunningApplication) -> Bool {
    if isProcessGone(app) {
      return true
    }

    _ = app.terminate()
    if waitForTermination(app: app, timeout: 5.0) {
      return true
    }

    _ = app.forceTerminate()
    return waitForTermination(app: app, timeout: 5.0)
  }

  private func waitForTermination(app: NSRunningApplication, timeout: TimeInterval) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if isProcessGone(app) {
        return true
      }
      Thread.sleep(forTimeInterval: 0.1)
    }
    return isProcessGone(app)
  }

  /// Reports whether the target process has exited.
  ///
  /// `NSRunningApplication.isTerminated` is a cached, KVO-backed property that
  /// AppKit only refreshes when the main run loop processes the workspace's
  /// termination notification. Since this runs synchronously on the main thread
  /// during `applicationWillFinishLaunching` (blocking the run loop), that
  /// property never updates here. We instead query the kernel directly with
  /// `kill(pid, 0)`, mirroring the Linux instance guard. The same-UID filtering
  /// in `prepareSingleInstanceStartup` means `EPERM` cannot occur for our own
  /// processes, so an `ESRCH` result reliably means the process is gone.
  private func isProcessGone(_ app: NSRunningApplication) -> Bool {
    if app.isTerminated {
      return true
    }
    return kill(app.processIdentifier, 0) != 0 && errno == ESRCH
  }

  private func processUID(for pid: pid_t) -> uid_t? {
    var info = proc_bsdinfo()
    let size = Int32(MemoryLayout<proc_bsdinfo>.stride)
    let result = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size)
    guard result == size else {
      return nil
    }
    return info.pbi_uid
  }

  /// The version of the currently launching build.
  private var currentVersion: AppVersion? {
    AppVersion(info: Bundle.main.infoDictionary)
  }

  /// Resolves the bundle version of an already-running instance.
  private func appVersion(for app: NSRunningApplication) -> AppVersion? {
    guard let bundleURL = app.bundleURL,
          let bundle = Bundle(url: bundleURL) else {
      return nil
    }
    return AppVersion(info: bundle.infoDictionary)
  }

  /// Returns the running instance with the highest version that is strictly
  /// newer than `version`, or nil if none of them is newer. Instances whose
  /// version cannot be read are treated as not-newer (they'll be terminated).
  private func newestApp(
    among apps: [NSRunningApplication],
    newerThan version: AppVersion
  ) -> NSRunningApplication? {
    apps
      .compactMap { app -> (app: NSRunningApplication, version: AppVersion)? in
        guard let appVersion = appVersion(for: app) else { return nil }
        return (app, appVersion)
      }
      .filter { $0.version > version }
      .max { $0.version < $1.version }?
      .app
  }

  @objc private func showMainWindowFromInstanceRequest(_ notification: Notification) {
    DispatchQueue.main.async {
      NSApp.unhide(nil)
      let window = NSApp.windows.first { $0 is MainFlutterWindow }
        ?? NSApp.mainWindow
        ?? NSApp.windows.first
      window?.deminiaturize(nil)
      window?.makeKeyAndOrderFront(nil)
      window?.orderFrontRegardless()
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  private func failStartup(_ message: String) -> Never {
    if let data = "Fluent Lyrics startup failed: \(message)\n".data(using: .utf8) {
      FileHandle.standardError.write(data)
    }

    let alert = NSAlert()
    alert.messageText = "Fluent Lyrics startup failed"
    alert.informativeText = message
    alert.alertStyle = .critical
    alert.runModal()
    exit(1)
  }
}

/// A comparable representation of a bundle's version, derived from its
/// Info.plist. Ordering is by `CFBundleShortVersionString` first and
/// `CFBundleVersion` (build number) as a tie-breaker, both compared with
/// numeric-aware semantics so "0.0.9" < "0.0.10".
private struct AppVersion: Comparable {
  let shortVersion: String
  let buildVersion: String

  init?(info: [String: Any]?) {
    guard let info = info else {
      return nil
    }
    let short = info["CFBundleShortVersionString"] as? String ?? ""
    let build = info["CFBundleVersion"] as? String ?? ""
    guard !short.isEmpty || !build.isEmpty else {
      return nil
    }
    self.shortVersion = short
    self.buildVersion = build
  }

  static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
    let shortOrder = lhs.shortVersion.compare(rhs.shortVersion, options: .numeric)
    if shortOrder != .orderedSame {
      return shortOrder == .orderedAscending
    }
    return lhs.buildVersion.compare(rhs.buildVersion, options: .numeric) == .orderedAscending
  }

  static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
    lhs.shortVersion.compare(rhs.shortVersion, options: .numeric) == .orderedSame &&
      lhs.buildVersion.compare(rhs.buildVersion, options: .numeric) == .orderedSame
  }
}

private struct FileIdentity: Equatable {
  let device: UInt64
  let inode: UInt64

  init?(url: URL) {
    guard let attributes = try? FileManager.default.attributesOfItem(
      atPath: url.path
    ),
      let device = attributes[.systemNumber] as? NSNumber,
      let inode = attributes[.systemFileNumber] as? NSNumber
    else {
      return nil
    }

    self.device = device.uint64Value
    self.inode = inode.uint64Value
  }
}
