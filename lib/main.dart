import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/lyrics_provider.dart';
import 'screens/lyrics_screen.dart';
import 'services/tray_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..userAgent = 'FluentLyrics/git';
  }
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString(
      'assets/fonts/google/Outfit/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['Outfit font'], license);
  });

  // window_manager / tray_manager are desktop-only. Skip the bootstrap on
  // Android so the app keeps booting like before.
  TrayService? trayService;
  if (trayPlatformSupported) {
    WidgetsFlutterBinding.ensureInitialized();
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
    );
  }

  // Create the provider eagerly so the tray bridge can subscribe to it before
  // any widget mounts. Without this the tray would briefly observe the
  // defaults() snapshot and then re-sync once the screen wires up.
  final lyricsProvider = LyricsProvider();
  if (trayService != null) {
    _bindTrayToProvider(trayService, lyricsProvider);
    await _installCloseInterceptor(trayService, lyricsProvider);
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: lyricsProvider)],
      child: const MyApp(),
    ),
  );
}

/// Drives [tray] on/off and now-playing label from [provider] notifications.
///
/// Mirrors the user's `trayEnabled` setting and pushes the current track to
/// the tray menu so the popup label stays in sync.
void _bindTrayToProvider(TrayService tray, LyricsProvider provider) {
  bool lastEnabled = provider.trayEnabled.current;

  Future<void> applyEnabled(bool enabled) async {
    if (enabled) {
      await tray.enable();
      final metadata = provider.currentMetadata;
      await tray.updateFromMetadata(
        title: metadata?.title,
        artists: metadata?.artist,
      );
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
    if (enabled) {
      final metadata = provider.currentMetadata;
      unawaited(
        tray.updateFromMetadata(
          title: metadata?.title,
          artists: metadata?.artist,
        ),
      );
    }
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
