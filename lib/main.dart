import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'i18n/strings.g.dart';
import 'providers/appearance_controller.dart';
import 'providers/lyrics_provider.dart';
import 'screens/lyrics_screen.dart';
import 'services/kanji_reading_dictionary.dart';
import 'services/lyrics_stream_writer.dart';
import 'services/opencc/zh_conversion_service.dart';
import 'services/settings_service.dart';
import 'services/tray_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_locale_code.dart';
import 'widgets/provider_logo.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..userAgent = 'FluentLyrics/git';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString(
      'assets/fonts/Outfit/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['Outfit (font)'], license);
  });
  ZhConversionService.registerLicense();
  ProviderLogo.registerLicense();
  KanjiReadingDictionary.registerLicense();

  // Create the provider eagerly so the tray bridge can subscribe to it before
  // any widget mounts. Without this the tray would briefly observe the
  // defaults() snapshot and then re-sync once the screen wires up.
  final lyricsProvider = LyricsProvider();

  // window_manager / tray_manager are desktop-only. Skip the bootstrap on
  // Android so the app keeps booting like before.
  TrayService? trayService;
  _MainWindow? mainWindow;
  if (trayPlatformSupported) {
    // Resolve the native window once, before the tray exists: nativeapi's
    // getCurrent() answers the focused (or first) toplevel, so asking later
    // could pick up a different one.
    final window = WindowManager.instance.getCurrent();
    if (window != null) mainWindow = _MainWindow(window);
  }
  if (mainWindow != null) {
    final window = mainWindow;
    trayService = TrayService(
      onShowWindow: () async {
        window.show();
      },
      onHideWindow: () async {
        window.hide();
      },
      onQuit: () async {
        window.destroy();
      },
      onLyricsCandidateSelected: (candidate) {
        unawaited(lyricsProvider.selectCandidate(candidate));
      },
      onTranslationCandidateSelected: (candidate) {
        unawaited(lyricsProvider.selectTranslationCandidate(candidate));
      },
      onResumeFetch: () {
        lyricsProvider.resumeCandidateFetch();
      },
      onRefreshLyrics: () {
        unawaited(lyricsProvider.refetchLyrics());
      },
      onRefreshTranslations: () {
        unawaited(lyricsProvider.refetchTranslations());
      },
      onMarkAsPureMusic: () {
        unawaited(lyricsProvider.markCurrentTrackAsPureMusic());
      },
      onMarkTranslationSkipped: () {
        unawaited(lyricsProvider.markCurrentTranslationAsSkipped());
      },
    );
  }

  if (trayService != null && mainWindow != null) {
    final tray = trayService;
    mainWindow.onShownChanged = (shown) {
      unawaited(tray.updateWindowShown(shown));
    };
    _bindTrayToProvider(trayService, lyricsProvider);
    _installCloseInterceptor(mainWindow, trayService, lyricsProvider);
  }

  // Lyrics / translation streaming to plain text files is desktop-only —
  // Android paths trigger permission prompts that we explicitly do not want
  // to introduce. Linux / macOS users can pipe the output (e.g. `tail -F`)
  // into status bars, OBS, or other tooling.
  if (trayPlatformSupported) {
    LyricsStreamWriter(provider: lyricsProvider).start();
  }

  // Restore persisted locale (null = follow system).
  final settingsService = SettingsService();
  final savedLocale = appLocaleFromCode(await settingsService.getLocale());
  if (savedLocale != null) {
    LocaleSettings.setLocale(savedLocale);
  }

  final appearanceController = AppearanceController();
  await appearanceController.load();

  runApp(
    TranslationProvider(
      child: AppearanceScope(
        controller: appearanceController,
        child: MultiProvider(
          providers: [ChangeNotifierProvider.value(value: lyricsProvider)],
          child: const MyApp(),
        ),
      ),
    ),
  );
}

/// Drives [tray] on/off and pushes now-playing label + candidate lists from
/// [provider] notifications.
///
/// Mirrors the user's `trayEnabled` setting and keeps the tray menu (now
/// playing label, Lyrics submenu, Translations submenu) in sync.
void _bindTrayToProvider(TrayService tray, LyricsProvider provider) {
  bool lastEnabled = provider.trayEnabled.current;

  Future<void> pushCandidates() async {
    await tray.updateCandidates(
      lyricsCandidates: provider.candidates,
      translationCandidates: provider.translationCandidates,
      activeLyrics: provider.lyricsResult,
      activeTranslation: provider.translationResult,
      isFetching: provider.isFetching,
      isPausedForCandidates: provider.isPausedForCandidates,
      translationEnabled: provider.translationEnabled.current,
    );
  }

  Future<void> applyEnabled(bool enabled) async {
    if (enabled) {
      await tray.enable();
      final metadata = provider.currentMetadata;
      await tray.updateFromMetadata(
        title: metadata?.title,
        artists: metadata?.artist,
      );
      await pushCandidates();
    } else {
      await tray.disable();
    }
  }

  // Apply the persisted value on startup once settings have loaded. The
  // provider notifies after async load, so do an initial pass here and let
  // the listener catch the post-load value.
  unawaited(applyEnabled(lastEnabled));

  provider.addListener(() {
    final enabled = provider.trayEnabled.current;
    if (enabled != lastEnabled) {
      lastEnabled = enabled;
      unawaited(applyEnabled(enabled));
      return;
    }
    if (!enabled) return;
    final metadata = provider.currentMetadata;
    unawaited(
      tray.updateFromMetadata(
        title: metadata?.title,
        artists: metadata?.artist,
      ),
    );
    unawaited(pushCandidates());
  });
}

/// The app's native window, with the 0.5.x `windowManager` behaviour the tray
/// relies on: [show] restores a minimized window, and [destroy] closes past
/// the close interceptor.
///
/// Also tracks whether the window is on screen so the tray can offer either
/// "Show" or "Hide". nativeapi has no shown / hidden event, so [show] and
/// [hide] set the state directly and window events cover the rest: the user
/// minimizing it, or a second launch presenting it again.
class _MainWindow {
  _MainWindow(this.window) {
    window.addListener(_onWindowEvent);
  }

  final Window window;

  /// Set by [destroy] so the close interceptor lets that one request through.
  bool _destroying = false;

  /// The runner shows the window on the first frame, so start as shown.
  bool _shown = true;

  /// Called whenever [_shown] flips.
  void Function(bool shown)? onShownChanged;

  void show() {
    if (window.isMinimized) window.restore();
    window.show();
    window.focus();
    _setShown(true);
  }

  void hide() {
    window.hide();
    _setShown(false);
  }

  void _onWindowEvent(WindowEvent event) {
    switch (event) {
      case WindowMinimizedEvent():
        _setShown(false);
      case WindowRestoredEvent() || WindowFocusedEvent():
        // A hidden window cannot take focus, so focus means it is back.
        _setShown(true);
      default:
        break;
    }
  }

  void _setShown(bool shown) {
    if (_shown == shown) return;
    _shown = shown;
    onShownChanged?.call(shown);
  }

  /// Closes the window without asking [_installCloseInterceptor]. Closing the
  /// last window ends the app, as the platform runner decides.
  void destroy() {
    _destroying = true;
    if (!window.close()) _destroying = false;
  }
}

/// Intercepts the OS window-close signal so we can hide-to-tray instead of
/// terminating when the user has opted in.
///
/// Background work (media polling, lyrics fetch, translations) keeps running
/// while hidden because [LyricsProvider] owns its own lifecycle and the
/// Flutter engine pauses rendering automatically when the window is not
/// visible. To actually quit, the tray menu's "Quit" item or any other
/// explicit [_MainWindow.destroy] call must be used.
void _installCloseInterceptor(
  _MainWindow mainWindow,
  TrayService tray,
  LyricsProvider provider,
) {
  Future<void> quit() async {
    await tray.disable();
    mainWindow.destroy();
  }

  mainWindow.window.addListener((event) {
    if (event is! WindowCloseRequestedEvent) return;
    if (mainWindow._destroying) {
      mainWindow._destroying = false;
      return;
    }

    // Always hold the window open: either it hides to the tray, or the tray
    // is torn down first and the window is then destroyed.
    event.request.cancel();

    // Safety net: only hide if the user actually has the tray enabled AND it
    // is currently up. Otherwise hiding the window would strand the user
    // with no way to bring it back, so fall through to a real quit.
    final hideRequested = provider.hideToTrayOnClose.current;
    final canHide =
        hideRequested && provider.trayEnabled.current && tray.isEnabled;

    if (canHide) {
      mainWindow.hide();
      return;
    }

    unawaited(quit());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluent Lyrics',
      debugShowCheckedModeBanner: false,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(),
      home: const LyricsScreen(),
    );
  }
}
