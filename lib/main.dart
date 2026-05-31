import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'i18n/strings.g.dart';
import 'providers/lyrics_provider.dart';
import 'screens/lyrics_screen.dart';
import 'services/lyrics_stream_writer.dart';
import 'services/settings_service.dart';
import 'services/tray_service.dart';

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
      'assets/fonts/google/Outfit/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['Outfit font'], license);
  });

  // Create the provider eagerly so the tray bridge can subscribe to it before
  // any widget mounts. Without this the tray would briefly observe the
  // defaults() snapshot and then re-sync once the screen wires up.
  final lyricsProvider = LyricsProvider();

  // window_manager / tray_manager are desktop-only. Skip the bootstrap on
  // Android so the app keeps booting like before.
  TrayService? trayService;
  if (trayPlatformSupported) {
    await windowManager.ensureInitialized();
    trayService = TrayService(
      onShowWindow: () async {
        await windowManager.show();
        await windowManager.focus();
      },
      onHideWindow: () async {
        await windowManager.hide();
      },
      onQuit: () async {
        await windowManager.destroy();
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

  if (trayService != null) {
    _bindTrayToProvider(trayService, lyricsProvider);
    await _installCloseInterceptor(trayService, lyricsProvider);
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
  final savedLocaleTag = await settingsService.getLocale();
  if (savedLocaleTag != null) {
    final match = AppLocale.values.where(
      (l) => l.languageTag == savedLocaleTag,
    );
    if (match.isNotEmpty) {
      LocaleSettings.setLocale(match.first);
    }
  }

  runApp(
    TranslationProvider(
      child: MultiProvider(
        providers: [ChangeNotifierProvider.value(value: lyricsProvider)],
        child: const MyApp(),
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

/// Intercepts the OS window-close signal so we can hide-to-tray instead of
/// terminating when the user has opted in.
///
/// Background work (media polling, lyrics fetch, translations) keeps running
/// while hidden because [LyricsProvider] owns its own lifecycle and the
/// Flutter engine pauses rendering automatically when the window is not
/// visible. To actually quit, the tray menu's "Quit" item or any other
/// explicit `windowManager.destroy()` call must be used.
Future<void> _installCloseInterceptor(
  TrayService tray,
  LyricsProvider provider,
) async {
  await windowManager.setPreventClose(true);
  windowManager.addListener(_CloseInterceptor(tray: tray, provider: provider));
}

class _CloseInterceptor with WindowListener {
  _CloseInterceptor({required this.tray, required this.provider});

  final TrayService tray;
  final LyricsProvider provider;

  @override
  void onWindowClose() {
    // Safety net: only hide if the user actually has the tray enabled AND it
    // is currently up. Otherwise hiding the window would strand the user
    // with no way to bring it back, so fall through to a real quit.
    final hideRequested = provider.hideToTrayOnClose.current;
    final canHide =
        hideRequested && provider.trayEnabled.current && tray.isEnabled;

    if (canHide) {
      unawaited(windowManager.hide());
      return;
    }

    unawaited(_quit());
  }

  Future<void> _quit() async {
    await tray.disable();
    await windowManager.destroy();
  }
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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Outfit',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontWeight: FontWeight.w500,
            fontVariations: <FontVariation>[FontVariation('wght', 500)],
          ),
          bodyLarge: TextStyle(
            fontWeight: FontWeight.w500,
            fontVariations: <FontVariation>[FontVariation('wght', 500)],
          ),
        ),
        fontFamilyFallback: const ['sans-serif'],
      ),
      home: const LyricsScreen(),
    );
  }
}
