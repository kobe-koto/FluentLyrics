import 'dart:io';

import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/services/opencc/zh_conversion.dart';
import 'package:fluent_lyrics/services/opencc/zh_conversion_service.dart';
import 'package:flutter_test/flutter_test.dart';

Lyric _lyric(String text) => Lyric(startTime: Duration.zero, text: text);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dataDirectory;

  setUp(() {
    dataDirectory = Directory.systemTemp.createTempSync('opencc_assets_test');
  });

  tearDown(() {
    ZhConversionService.instance.reset();
    if (dataDirectory.existsSync()) {
      dataDirectory.deleteSync(recursive: true);
    }
  });

  test('extracts the bundled OpenCC data once', () async {
    final service = ZhConversionService.instance;

    await service.ensureInitialized(directory: dataDirectory);
    expect(service.isReady, isTrue);
    expect(File('${dataDirectory.path}/s2t.json').existsSync(), isTrue);
    expect(File('${dataDirectory.path}/t2s.json').existsSync(), isTrue);
    expect(File('${dataDirectory.path}/STPhrases.txt').existsSync(), isTrue);
    expect(File('${dataDirectory.path}/TSCharacters.txt').existsSync(), isTrue);
    expect(
      File('${dataDirectory.path}/version.txt').readAsStringSync().trim(),
      isNotEmpty,
    );

    // Calling again reuses the extracted data (and the cached future).
    final extracted = File('${dataDirectory.path}/s2t.json').lastModifiedSync();
    await service.ensureInitialized(directory: dataDirectory);
    expect(
      File('${dataDirectory.path}/s2t.json').lastModifiedSync(),
      extracted,
    );
  });

  test('converts lyrics with the bundled data and bundled library', () async {
    final service = ZhConversionService.instance;
    await service.ensureInitialized(directory: dataDirectory);

    final converted = service.convertLyrics(
      [_lyric('开放中文转换')],
      target: ZhConversionTarget.traditionalTaiwan,
      ignoredLanguages: const ['ja'],
    );
    expect(converted.first.text, '開放中文轉換');

    final simplified = service.convertLyrics(
      [_lyric('開放中文轉換')],
      target: ZhConversionTarget.simplified,
      ignoredLanguages: const ['ja'],
    );
    expect(simplified.first.text, '开放中文转换');
  });

  test('leaves Japanese lyrics untouched', () async {
    final service = ZhConversionService.instance;
    await service.ensureInitialized(directory: dataDirectory);

    final lyrics = [_lyric('東京は晴れ'), _lyric('研究会')];
    final converted = service.convertLyrics(
      lyrics,
      target: ZhConversionTarget.traditionalTaiwan,
      ignoredLanguages: const ['ja'],
    );

    expect(identical(converted, lyrics), isTrue);
  });
}
