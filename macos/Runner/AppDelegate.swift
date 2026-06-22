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
    if app.isTerminated {
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
      if app.isTerminated {
        return true
      }
      Thread.sleep(forTimeInterval: 0.1)
    }
    return app.isTerminated
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
