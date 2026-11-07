import 'package:fluent_lyrics/models/lyric_provider_type.dart';
import 'package:fluent_lyrics/widgets/provider_logo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every catalog provider ships a parseable logo', () async {
    for (final type in LyricProviderType.values) {
      final asset = type.logoAsset;
      if (type == LyricProviderType.cache) {
        expect(asset, isNull);
        continue;
      }
      expect(asset, isNotNull, reason: '$type has no logo');
      final svg = await rootBundle.loadString(asset!);
      expect(svg, isNot(contains('<style')), reason: '$asset uses CSS');
      final loader = SvgStringLoader(svg);
      await vg.loadPicture(loader, null);
    }
  });

  test('logo notice is registered on the license page', () async {
    ProviderLogo.registerLicense();
    final entries = await LicenseRegistry.licenses.toList();
    final logos = entries.where(
      (entry) => entry.packages.contains('Provider logos'),
    );
    expect(logos, isNotEmpty);
    final text = logos.first.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('Font Awesome Free'));
    expect(text, contains('CC BY 4.0'));
    expect(text, contains('MIT License'));
  });

  testWidgets('disabled logos are drawn in grayscale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            ProviderLogo(type: LyricProviderType.musixmatch),
            ProviderLogo(type: LyricProviderType.netease, enabled: false),
          ],
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(SvgPicture).last,
        matching: find.byType(ColorFiltered),
      ),
      findsOneWidget,
    );
  });
}
