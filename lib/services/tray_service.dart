import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import '../models/lyric_model.dart';
import '../utils/app_logger.dart';

/// Whether the host platform can run a desktop system tray at all.
///
/// FluentLyrics only ships a tray on Linux (AppIndicator / StatusNotifierItem)
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
class TrayService with TrayListener {
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
    final items = <MenuItem>[];
    final label = _nowPlayingLabel();
    if (label != null) {
      items.add(MenuItem(key: 'now_playing', label: label, disabled: true));
      items.add(MenuItem.separator());
    }
    items.add(_buildLyricsSubmenu());
    items.add(_buildTranslationsSubmenu());
    items
      ..add(MenuItem.separator())
      ..add(MenuItem(key: 'show_window', label: 'Show window'))
      ..add(MenuItem(key: 'hide_window', label: 'Hide window'))
      ..add(MenuItem.separator())
      ..add(MenuItem(key: 'quit', label: 'Quit Fluent Lyrics'));
    await trayManager.setContextMenu(Menu(items: items));
  }

  MenuItem _buildLyricsSubmenu() {
    final children = <MenuItem>[];

    if (_isPausedForCandidates) {
      children
        ..add(MenuItem(key: 'continue_fetch', label: 'Continue searching…'))
        ..add(MenuItem.separator());
    }

    if (_lyricsCandidates.isEmpty) {
      children.add(
        MenuItem(
          key: 'lyrics_empty',
          label: _isFetching ? 'Searching providers…' : 'No candidates yet',
          disabled: true,
        ),
      );
    } else {
      for (var i = 0; i < _lyricsCandidates.length; i++) {
        final candidate = _lyricsCandidates[i];
        final isActive = _lyricsMatches(candidate, _activeLyrics);
        children.add(
          MenuItem(
            key: 'lyrics_$i',
            label: _lyricsLabel(candidate, isActive: isActive),
            disabled: isActive,
          ),
        );
      }
      if (_isFetching) {
        children
          ..add(MenuItem.separator())
          ..add(
            MenuItem(
              key: 'lyrics_fetching',
              label: 'Searching for more…',
              disabled: true,
            ),
          );
      }
    }

    children
      ..add(MenuItem.separator())
      ..add(MenuItem(key: 'lyrics_refresh', label: 'Refresh lyrics'))
      ..add(
        MenuItem(key: 'lyrics_mark_pure_music', label: 'Mark as pure music'),
      );

    return MenuItem.submenu(
      key: 'lyrics_submenu',
      label: 'Lyrics',
      submenu: Menu(items: children),
    );
  }

  MenuItem _buildTranslationsSubmenu() {
    final children = <MenuItem>[];

    if (_translationEnabled && _isPausedForCandidates) {
      children
        ..add(MenuItem(key: 'continue_fetch', label: 'Continue searching…'))
        ..add(MenuItem.separator());
    }

    if (!_translationEnabled) {
      children.add(
        MenuItem(
          key: 'translations_disabled',
          label: 'Translation disabled in settings',
          disabled: true,
        ),
      );
    } else if (_translationCandidates.isEmpty) {
      children.add(
        MenuItem(
          key: 'translations_empty',
          label: _isFetching
              ? 'Searching translations…'
              : 'No alternatives found',
          disabled: true,
        ),
      );
    } else {
      for (var i = 0; i < _translationCandidates.length; i++) {
        final candidate = _translationCandidates[i];
        final isActive = _translationMatches(candidate, _activeTranslation);
        children.add(
          MenuItem(
            key: 'translation_$i',
            label: _translationLabel(candidate, isActive: isActive),
            disabled: isActive,
          ),
        );
      }
      if (_isFetching) {
        children
          ..add(MenuItem.separator())
          ..add(
            MenuItem(
              key: 'translations_fetching',
              label: 'Searching for more…',
              disabled: true,
            ),
          );
      }
    }

    if (_translationEnabled) {
      children
        ..add(MenuItem.separator())
        ..add(
          MenuItem(key: 'translations_refresh', label: 'Refresh translations'),
        )
        ..add(
          MenuItem(
            key: 'translations_mark_skipped',
            label: 'Mark translation as skipped',
          ),
        );
    }

    return MenuItem.submenu(
      key: 'translations_submenu',
      label: 'Translations',
      submenu: Menu(items: children),
    );
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
    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (e, st) {
      AppLogger.debug('TrayService.destroy failed: $e\n$st');
    }
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
    final key = menuItem.key;
    if (key == null) return;
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
