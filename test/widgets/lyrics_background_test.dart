import 'dart:convert';
import 'dart:typed_data';

import 'package:fluent_lyrics/widgets/screen/lyrics/lyrics_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'motion background uses placeholder color before bake completes',
    (tester) async {
      const placeholderColor = Color(0xFF123456);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.expand(
            child: LyricsBackground(
              artProvider: MemoryImage(_onePixelPng),
              motionEnabled: true,
              placeholderColor: placeholderColor,
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Container && widget.color == placeholderColor,
        ),
        findsOneWidget,
      );
    },
  );
}

final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9p2Xc6sAAAAASUVORK5CYII=',
);
