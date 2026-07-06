import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let mediaService = MacOSMediaService()
  private var mediaChannel: FlutterMethodChannel?
  private var mediaEventsChannel: FlutterEventChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    mediaChannel = FlutterMethodChannel(
      name: "cc.koto.fluent_lyrics/media",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    mediaChannel?.setMethodCallHandler(mediaService.handle)
    mediaEventsChannel = FlutterEventChannel(
      name: "cc.koto.fluent_lyrics/media_events",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    mediaEventsChannel?.setStreamHandler(mediaService)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
