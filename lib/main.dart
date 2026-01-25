import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/lyrics_provider.dart';
import 'screens/lyrics_screen.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString(
      'assets/fonts/google/Outfit/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['Outfit font'], license);
  });

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LyricsProvider())],
      child: const MyApp(),
    ),
  );
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
