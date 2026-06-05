import 'package:fluent_lyrics/main.dart';
import 'package:fluent_lyrics/i18n/strings.g.dart';
import 'package:fluent_lyrics/providers/lyrics_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MyApp builds the default lyrics screen shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    LocaleSettings.setLocaleSync(AppLocale.en);

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider(
          create: (_) => LyricsProvider(),
          child: const MyApp(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No Media Playing'), findsOneWidget);
    expect(find.text('Start playing music'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Fluent Lyrics');
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(app.theme?.brightness, Brightness.dark);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
