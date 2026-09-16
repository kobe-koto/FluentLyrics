import 'package:fluent_lyrics/services/opencc/zh_conversion_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Joins the paragraphs of every registered entry for the given package.
Future<String> _licenseTextFor(String package) async {
  final entries = await LicenseRegistry.licenses
      .where((entry) => entry.packages.contains(package))
      .toList();
  final buffer = StringBuffer();
  for (final entry in entries) {
    for (final paragraph in entry.paragraphs) {
      buffer.writeln(paragraph.text);
    }
  }
  return buffer.toString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ships the OpenCC license and attribution next to the dictionaries',
    () async {
      final license = await rootBundle.loadString(
        ZhConversionService.licenseAsset,
      );
      expect(license, contains('Apache License'));
      expect(license, contains('Version 2.0, January 2004'));

      final notice = await rootBundle.loadString(
        ZhConversionService.noticeAsset,
      );
      expect(notice, contains('github.com/BYVoid/OpenCC'));
      expect(notice, contains('Apache License, Version 2.0'));

      final authors = await rootBundle.loadString(
        ZhConversionService.authorsAsset,
      );
      expect(authors, contains('Carbo Kuo'));
    },
  );

  test('registerLicense registers the license for the license page', () async {
    ZhConversionService.registerLicense();

    final text = await _licenseTextFor('OpenCC');
    expect(text, contains('Apache License'));
    expect(text, contains('Version 2.0, January 2004'));
    // Attribution has to travel with the license (Apache-2.0 section 4).
    expect(text, contains('github.com/BYVoid/OpenCC'));
    expect(text, contains('Carbo Kuo'));
  });
}
