import 'package:fluent_lyrics/theme/monospace_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('monospace text does not inherit the variable weight axis', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
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
        home: Scaffold(
          body: TextField(
            style: monospaceTextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );

    final style = tester.widget<EditableText>(find.byType(EditableText)).style;
    expect(style.fontFamily, 'monospace');
    expect(style.fontVariations, isEmpty);
    expect(
      style.fontVariations?.any((variation) => variation.axis == 'wght'),
      isFalse,
    );
    expect(style.fontWeight, FontWeight.w400);
  });
}
