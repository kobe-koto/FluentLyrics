import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import '../utils/app_logger.dart';

/// Whether the host platform can run a desktop system tray at all.
///
/// FluentLyrics only ships a tray on Linux (AppIndicator / StatusNotifierItem)
/// and macOS (NSStatusItem). Android explicitly has no tray.
bool get trayPlatformSupported => Platform.isLinux || Platform.isMacOS;

/// Owns the lifecycle of the OS system tray icon and its context menu.
///
/// Construction does nothing. Call [enable] to actually create the tray icon
/// and [disable] to tear it down. Both are idempotent so they can be driven
/// directly from a settings toggle.
class TrayService with TrayListener {
  TrayService({
    required this.onShowWindow,
    required this.onHideWindow,
    required this.onQuit,
  });

  /// Show / focus the main window. Wired from main.dart to window_manager.
  final Future<void> Function() onShowWindow;

  /// Hide the main window to the tray. Wired from main.dart to window_manager.
  final Future<void> Function() onHideWindow;

  /// Quit the application. Wired from main.dart.
  final Future<void> Function() onQuit;

  bool _enabled = false;
  String? _trackTitle;
  String? _trackArtist;

  bool get isEnabled => _enabled;

  /// Create the tray icon and install the default menu.
  ///
  /// Safe to call multiple times; only the first call has effect.
  Future<void> enable() async {
    if (!trayPlatformSupported || _enabled) return;
    try {
      trayManager.addListener(this);
      await trayManager.setIcon(_iconPath());
      if (!Platform.isLinux) {
        await trayManager.setToolTip('Fluent Lyrics');
      }
      await _refreshMenu();
      _enabled = true;
    } catch (e, st) {
      AppLogger.debug('TrayService.enable failed: $e\n$st');
      // Best-effort cleanup so a partially-initialised tray does not leak.
      await _tearDownInternal();
    }
  }

  /// Destroy the tray icon and remove listeners.
  ///
  /// Safe to call multiple times.
  Future<void> disable() async {
    if (!trayPlatformSupported || !_enabled) return;
    await _tearDownInternal();
  }

  /// Update the now-playing line shown at the top of the tray menu.
  ///
  /// No-op when the tray is disabled or on unsupported platforms.
  Future<void> updateNowPlaying({
    String? title,
    String? artist,
  }) async {
    if (!_enabled) return;
    final next = (title == null || title.isEmpty) ? null : title;
    final nextArtist = (artist == null || artist.isEmpty) ? null : artist;
    if (next == _trackTitle && nextArtist == _trackArtist) return;
    _trackTitle = next;
    _trackArtist = nextArtist;
    await _refreshMenu();
  }

  /// Convenience hook for callers holding a [LyricsResult] / metadata pair.
  Future<void> updateFromMetadata({
    required String? title,
    required List<String>? artists,
  }) async {
    await updateNowPlaying(
      title: title,
      artist: (artists == null || artists.isEmpty) ? null : artists.join(', '),
    );
  }

  String _iconPath() {
    // assets/icons/logo-rounded.png is bundled via flutter_launcher_icons input and is
    // the only icon shipped today; reuse it for the tray. macOS users may
    // later swap in a template variant in assets/icons/.
    return 'assets/icons/logo-rounded.png';
  }

  Future<void> _refreshMenu() async {
    final items = <MenuItem>[];
    final label = _nowPlayingLabel();
    if (label != null) {
      items.add(MenuItem(key: 'now_playing', label: label, disabled: true));
      items.add(MenuItem.separator());
    }
    items
      ..add(MenuItem(key: 'show_window', label: 'Show window'))
      ..add(MenuItem(key: 'hide_window', label: 'Hide window'))
      ..add(MenuItem.separator())
      ..add(MenuItem(key: 'quit', label: 'Quit Fluent Lyrics'));
    await trayManager.setContextMenu(Menu(items: items));
  }

  String? _nowPlayingLabel() {
    final title = _trackTitle;
    if (title == null) return null;
    final artist = _trackArtist;
    if (artist == null) return title;
    return '$title — $artist';
  }

  Future<void> _tearDownInternal() async {
    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (e, st) {
      AppLogger.debug('TrayService.destroy failed: $e\n$st');
    }
    _enabled = false;
    _trackTitle = null;
    _trackArtist = null;
  }

  @override
  void onTrayIconMouseDown() {
    // macOS / Windows: left-click should open the menu. Linux AppIndicator
    // opens the menu on its own, so we skip popping it up there.
    if (Platform.isLinux) return;
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isLinux) return;
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        unawaited(onShowWindow());
        break;
      case 'hide_window':
        unawaited(onHideWindow());
        break;
      case 'quit':
        unawaited(_handleQuit());
        break;
    }
  }

  Future<void> _handleQuit() async {
    await disable();
    await onQuit();
  }
}
