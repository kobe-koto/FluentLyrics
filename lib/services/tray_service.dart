import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import '../models/lyric_model.dart';
import '../utils/app_logger.dart';

/// Whether the host platform can run a desktop system tray at all.
///
/// FluentLyrics only ships a tray on Linux (StatusNotifierItem)
/// and macOS (NSStatusItem). Android explicitly has no tray.
bool get trayPlatformSupported => Platform.isLinux || Platform.isMacOS;

/// Hard cap on how many candidates are exposed via the tray submenus.
///
/// Real tracks rarely produce more than a handful, but cap defensively so a
/// runaway candidate stream cannot blow up the system menu.
const int _maxTrayCandidates = 20;

/// Owns the lifecycle of the OS system tray icon and its context menu.
///
/// Construction does nothing. Call [enable] to actually create the tray icon
/// and [disable] to tear it down. Both are idempotent so they can be driven
/// directly from a settings toggle.
class TrayService {
  TrayService({
    required this.onShowWindow,
    required this.onHideWindow,
    required this.onQuit,
    required this.onLyricsCandidateSelected,
    required this.onTranslationCandidateSelected,
    required this.onResumeFetch,
    required this.onRefreshLyrics,
    required this.onRefreshTranslations,
    required this.onMarkAsPureMusic,
    required this.onMarkTranslationSkipped,
  });

  /// Show / focus the main window. Wired from main.dart to window_manager.
  final Future<void> Function() onShowWindow;

  /// Hide the main window to the tray. Wired from main.dart to window_manager.
  final Future<void> Function() onHideWindow;

  /// Quit the application. Wired from main.dart.
  final Future<void> Function() onQuit;

  /// Apply a lyrics candidate chosen from the "Lyrics" submenu.
  final void Function(LyricsResult candidate) onLyricsCandidateSelected;

  /// Apply a translation candidate chosen from the "Translations" submenu.
  final void Function(LyricsResult candidate) onTranslationCandidateSelected;

  /// Resume a candidate fetch that paused after a "good enough" result.
  final void Function() onResumeFetch;

  /// Re-run the lyrics search for the current track, bypassing cache.
  final void Function() onRefreshLyrics;

  /// Re-run the translation search for the current track, bypassing cache.
  final void Function() onRefreshTranslations;

  /// Mark the current track as instrumental / pure music.
  final void Function() onMarkAsPureMusic;

  /// Mark the current track's translation as deliberately skipped.
  final void Function() onMarkTranslationSkipped;

  bool _enabled = false;
  String? _trackTitle;
  String? _trackArtist;
  List<LyricsResult> _lyricsCandidates = const [];
  List<LyricsResult> _translationCandidates = const [];
  LyricsResult? _activeLyrics;
  LyricsResult? _activeTranslation;
  bool _isFetching = false;
  bool _isPausedForCandidates = false;
  bool _translationEnabled = false;
  TrayIcon? _trayIcon;
  ListenerId? _trayIconListenerId;
  Image? _icon;
  _TrayMenuBinding? _menuBinding;

  bool get isEnabled => _enabled;

  /// Create the tray icon and install the default menu.
  ///
  /// Safe to call multiple times; only the first call has effect.
  Future<void> enable() async {
    if (!trayPlatformSupported || _enabled) return;
    try {
      final trayIcon = TrayIcon.create();
      if (trayIcon == null) {
        throw StateError('Unable to create the tray icon');
      }
      _trayIcon = trayIcon;
      _trayIconListenerId = trayIcon.addListener(_onTrayIconEvent);
      final icon = ImageAsset.fromAsset(_iconPath());
      if (icon == null) {
        throw ArgumentError.value(_iconPath(), 'iconPath');
      }
      _icon = icon;
      trayIcon.icon = icon;
      trayIcon.setTooltip('Fluent Lyrics');
      // Let the native tray host open the menu on a secondary click. The
      // primary click is delivered to [_onTrayIconEvent] so it can show the
      // application window instead.
      trayIcon.setContextMenuTrigger(ContextMenuTrigger.rightClicked);
      trayIcon.setVisible(true);
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
  Future<void> updateNowPlaying({String? title, String? artist}) async {
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

  /// Replace the candidate lists shown under the "Lyrics" / "Translations"
  /// submenus.
  ///
  /// [activeLyrics] / [activeTranslation] should be the currently-applied
  /// entries so the matching items get a bullet marker. Truncated to
  /// [_maxTrayCandidates].
  Future<void> updateCandidates({
    required List<LyricsResult> lyricsCandidates,
    required List<LyricsResult> translationCandidates,
    required LyricsResult? activeLyrics,
    required LyricsResult? activeTranslation,
    required bool isFetching,
    required bool isPausedForCandidates,
    required bool translationEnabled,
  }) async {
    if (!_enabled) return;
    final trimmedLyrics = _trim(lyricsCandidates);
    final trimmedTranslations = _trim(translationCandidates);
    if (_candidatesEqual(trimmedLyrics, _lyricsCandidates) &&
        _candidatesEqual(trimmedTranslations, _translationCandidates) &&
        _lyricsMatches(_activeLyrics, activeLyrics) &&
        _translationMatches(_activeTranslation, activeTranslation) &&
        _isFetching == isFetching &&
        _isPausedForCandidates == isPausedForCandidates &&
        _translationEnabled == translationEnabled) {
      return;
    }
    _lyricsCandidates = List.unmodifiable(trimmedLyrics);
    _translationCandidates = List.unmodifiable(trimmedTranslations);
    _activeLyrics = activeLyrics;
    _activeTranslation = activeTranslation;
    _isFetching = isFetching;
    _isPausedForCandidates = isPausedForCandidates;
    _translationEnabled = translationEnabled;
    await _refreshMenu();
  }

  List<LyricsResult> _trim(List<LyricsResult> candidates) {
    if (candidates.length <= _maxTrayCandidates) return candidates;
    return candidates.sublist(0, _maxTrayCandidates);
  }

  String _iconPath() {
    return 'assets/icons/logo-rounded.png';
  }

  Future<void> _refreshMenu() async {
    final binding = _TrayMenuBinding(onItemClicked: _onTrayMenuItemClick);
    final menu = binding.createMenu();
    final label = _nowPlayingLabel();
    if (label != null) {
      binding.addItem(menu, 'now_playing', label, disabled: true);
      binding.addSeparator(menu);
    }
    binding.addItem(
      menu,
      'lyrics_submenu',
      'Lyrics',
      submenu: _buildLyricsSubmenu(binding),
    );
    binding.addItem(
      menu,
      'translations_submenu',
      'Translations',
      submenu: _buildTranslationsSubmenu(binding),
    );
    binding
      ..addSeparator(menu)
      ..addItem(menu, 'show_window', 'Show window')
      ..addItem(menu, 'hide_window', 'Hide window')
      ..addSeparator(menu)
      ..addItem(menu, 'quit', 'Quit Fluent Lyrics');

    _trayIcon!.setContextMenu(menu);
    final previous = _menuBinding;
    _menuBinding = binding;
    if (previous != null) Timer.run(previous.dispose);
  }

  Menu _buildLyricsSubmenu(_TrayMenuBinding binding) {
    final menu = binding.createMenu();

    if (_isPausedForCandidates) {
      binding.addItem(menu, 'continue_fetch', 'Continue searching…');
      binding.addSeparator(menu);
    }

    if (_lyricsCandidates.isEmpty) {
      binding.addItem(
        menu,
        'lyrics_empty',
        _isFetching ? 'Searching providers…' : 'No candidates yet',
        disabled: true,
      );
    } else {
      for (var i = 0; i < _lyricsCandidates.length; i++) {
        final candidate = _lyricsCandidates[i];
        final isActive = _lyricsMatches(candidate, _activeLyrics);
        binding.addItem(
          menu,
          'lyrics_$i',
          _lyricsLabel(candidate, isActive: isActive),
          disabled: isActive,
        );
      }
      if (_isFetching) {
        binding.addSeparator(menu);
        binding.addItem(
          menu,
          'lyrics_fetching',
          'Searching for more…',
          disabled: true,
        );
      }
    }

    binding.addSeparator(menu);
    binding.addItem(menu, 'lyrics_refresh', 'Refresh lyrics');
    binding.addItem(menu, 'lyrics_mark_pure_music', 'Mark as pure music');
    return menu;
  }

  Menu _buildTranslationsSubmenu(_TrayMenuBinding binding) {
    final menu = binding.createMenu();

    if (_translationEnabled && _isPausedForCandidates) {
      binding.addItem(menu, 'continue_fetch', 'Continue searching…');
      binding.addSeparator(menu);
    }

    if (!_translationEnabled) {
      binding.addItem(
        menu,
        'translations_disabled',
        'Translation disabled in settings',
        disabled: true,
      );
    } else if (_translationCandidates.isEmpty) {
      binding.addItem(
        menu,
        'translations_empty',
        _isFetching ? 'Searching translations…' : 'No alternatives found',
        disabled: true,
      );
    } else {
      for (var i = 0; i < _translationCandidates.length; i++) {
        final candidate = _translationCandidates[i];
        final isActive = _translationMatches(candidate, _activeTranslation);
        binding.addItem(
          menu,
          'translation_$i',
          _translationLabel(candidate, isActive: isActive),
          disabled: isActive,
        );
      }
      if (_isFetching) {
        binding.addSeparator(menu);
        binding.addItem(
          menu,
          'translations_fetching',
          'Searching for more…',
          disabled: true,
        );
      }
    }

    if (_translationEnabled) {
      binding.addSeparator(menu);
      binding.addItem(menu, 'translations_refresh', 'Refresh translations');
      binding.addItem(
        menu,
        'translations_mark_skipped',
        'Mark translation as skipped',
      );
    }

    return menu;
  }

  String _lyricsLabel(LyricsResult candidate, {required bool isActive}) {
    final source = candidate.source.replaceAll(' (cached)', '');
    final sync = _syncLabel(candidate);
    final marker = isActive ? '● ' : '';
    return '$marker$source — $sync';
  }

  String _translationLabel(LyricsResult candidate, {required bool isActive}) {
    final provider = (candidate.translationProvider ?? 'Unknown').replaceAll(
      ' (cached)',
      '',
    );
    final lang = (candidate.language ?? '?').toUpperCase();
    final marker = isActive ? '● ' : '';
    return '$marker$provider — $lang';
  }

  String _syncLabel(LyricsResult candidate) {
    if (candidate.isPureMusic) return 'Instrumental';
    if (candidate.isRichSync) return 'Rich Sync';
    if (candidate.isSynced) return 'Synced';
    return 'Plain';
  }

  /// Mirrors `_isActive` in lyrics_candidate_sheet.dart's _LyricsTab so the
  /// tray and sheet agree on which entry is "currently applied".
  bool _lyricsMatches(LyricsResult? a, LyricsResult? b) {
    if (a == null || b == null) return identical(a, b);
    final aSrc = a.source.replaceAll(' (cached)', '');
    final bSrc = b.source.replaceAll(' (cached)', '');
    return aSrc == bSrc &&
        a.isSynced == b.isSynced &&
        a.isRichSync == b.isRichSync;
  }

  /// Mirrors `_isActive` in lyrics_candidate_sheet.dart's _TranslationTab.
  bool _translationMatches(LyricsResult? a, LyricsResult? b) {
    if (a == null || b == null) return identical(a, b);
    final aProv = (a.translationProvider ?? '').replaceAll(' (cached)', '');
    final bProv = (b.translationProvider ?? '').replaceAll(' (cached)', '');
    return aProv == bProv && a.language == b.language;
  }

  bool _candidatesEqual(List<LyricsResult> a, List<LyricsResult> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      // Reference equality is enough: LyricsProvider builds a new list when
      // the underlying candidate set changes, and never mutates existing
      // LyricsResult instances in place.
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  String? _nowPlayingLabel() {
    final title = _trackTitle;
    if (title == null) return null;
    final artist = _trackArtist;
    if (artist == null) return title;
    return '$title — $artist';
  }

  Future<void> _tearDownInternal() async {
    final trayIcon = _trayIcon;
    final trayIconListenerId = _trayIconListenerId;
    if (trayIcon != null && trayIconListenerId != null) {
      trayIcon.removeListener(trayIconListenerId);
    }
    trayIcon?.setContextMenu(null);
    _menuBinding?.dispose();
    _menuBinding = null;
    try {
      _icon?.dispose();
      _icon = null;
      trayIcon?.dispose();
    } catch (e, st) {
      AppLogger.debug('TrayService.dispose failed: $e\n$st');
    }
    _trayIcon = null;
    _trayIconListenerId = null;
    _enabled = false;
    _trackTitle = null;
    _trackArtist = null;
    _lyricsCandidates = const [];
    _translationCandidates = const [];
    _activeLyrics = null;
    _activeTranslation = null;
    _isFetching = false;
    _isPausedForCandidates = false;
    _translationEnabled = false;
  }

  void _onTrayIconEvent(TrayIconEvent event) {
    if (event is TrayIconClickedEvent) {
      unawaited(onShowWindow());
    }
  }

  void _onTrayMenuItemClick(String key) {
    switch (key) {
      case 'show_window':
        unawaited(onShowWindow());
        return;
      case 'hide_window':
        unawaited(onHideWindow());
        return;
      case 'quit':
        unawaited(_handleQuit());
        return;
      case 'continue_fetch':
        onResumeFetch();
        return;
      case 'lyrics_refresh':
        onRefreshLyrics();
        return;
      case 'lyrics_mark_pure_music':
        onMarkAsPureMusic();
        return;
      case 'translations_refresh':
        onRefreshTranslations();
        return;
      case 'translations_mark_skipped':
        onMarkTranslationSkipped();
        return;
    }
    // Candidate keys are `lyrics_<index>` / `translation_<index>`. Always
    // read from the live snapshot — the menu the user just clicked could be
    // stale if a fetch finished mid-click.
    if (key.startsWith('lyrics_')) {
      final index = int.tryParse(key.substring('lyrics_'.length));
      if (index == null) return;
      if (index < 0 || index >= _lyricsCandidates.length) return;
      onLyricsCandidateSelected(_lyricsCandidates[index]);
      return;
    }
    if (key.startsWith('translation_')) {
      final index = int.tryParse(key.substring('translation_'.length));
      if (index == null) return;
      if (index < 0 || index >= _translationCandidates.length) return;
      onTranslationCandidateSelected(_translationCandidates[index]);
      return;
    }
  }

  Future<void> _handleQuit() async {
    await disable();
    await onQuit();
  }
}

/// Owns the native menu tree and every listener registered on its items.
/// Native menus retain handles asynchronously, so the previous binding is
/// disposed on the next event-loop turn after a replacement is installed.
class _TrayMenuBinding {
  _TrayMenuBinding({required this.onItemClicked});

  final void Function(String key) onItemClicked;
  final List<Menu> _menus = <Menu>[];
  final List<MenuItem> _items = <MenuItem>[];
  final List<(MenuItem, ListenerId)> _listeners = <(MenuItem, ListenerId)>[];

  Menu createMenu() {
    final menu = Menu.create();
    if (menu == null) throw StateError('Unable to create the tray menu');
    _menus.add(menu);
    return menu;
  }

  void addSeparator(Menu menu) => menu.addSeparator();

  void addItem(
    Menu menu,
    String key,
    String label, {
    bool disabled = false,
    Menu? submenu,
  }) {
    final type = submenu == null ? MenuItemType.normal : MenuItemType.submenu;
    final item = MenuItem.createWithLabelAndType(label, type);
    if (item == null) throw StateError('Unable to create tray item $label');
    item.isEnabled = !disabled;
    if (submenu != null) item.submenu = submenu;
    final listenerId = item.addListener((event) {
      if (event is MenuItemClickedEvent) onItemClicked(key);
    });
    _items.add(item);
    _listeners.add((item, listenerId));
    menu.addItem(item);
  }

  void dispose() {
    for (final (item, listenerId) in _listeners) {
      item.removeListener(listenerId);
    }
    for (final item in _items) {
      item.dispose();
    }
    for (final menu in _menus) {
      menu.dispose();
    }
    _listeners.clear();
    _items.clear();
    _menus.clear();
  }
}
