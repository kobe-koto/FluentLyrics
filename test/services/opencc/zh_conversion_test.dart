import 'dart:io';

import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/services/opencc/zh_conversion.dart';
import 'package:fluent_lyrics/services/opencc/zh_converter.dart';
import 'package:flutter_test/flutter_test.dart';

String? _hostLibraryPath() {
  final name = Platform.isLinux
      ? 'libopencc.so'
      : Platform.isMacOS
      ? 'libopencc.dylib'
      : null;
  if (name == null) return null;
  final file = File('build/opencc/out/lib/$name');
  return file.existsSync() ? file.absolute.path : null;
}

const String _hostDataDirectory = 'build/opencc/out/share/opencc';

Lyric _lyric(
  String text, {
  String? translation,
  List<LyricInlinePart>? parts,
}) => Lyric(
  startTime: Duration.zero,
  text: text,
  translation: translation,
  inlineParts: parts,
);

void main() {
  final libraryPath = _hostLibraryPath();
  final dataDirectoryExists = Directory(_hostDataDirectory).existsSync();
  final skipReason = libraryPath == null || !dataDirectoryExists
      ? 'run tool/build_opencc.sh first'
      : null;

  ZhConverter open(ZhConfig config) => ZhConverter.open(
    config,
    dataDirectory: _hostDataDirectory,
    libraryPath: libraryPath,
  );

  group('ZhConversionTarget', () {
    test('maps setting values onto OpenCC configs', () {
      expect(ZhConversionTarget.fromSetting('off').config, isNull);
      expect(ZhConversionTarget.fromSetting('zh_CN').config, ZhConfig.t2s);
      expect(ZhConversionTarget.fromSetting('zh_TW').config, ZhConfig.s2twp);
      expect(ZhConversionTarget.fromSetting('zh_HK').config, ZhConfig.s2hk);
      expect(
        ZhConversionTarget.fromSetting('nonsense'),
        ZhConversionTarget.off,
      );
      expect(ZhConversionTarget.fromSetting(null), ZhConversionTarget.off);
    });
  });

  group('ZhConversion.shouldSkip', () {
    test('skips Japanese lyrics by default', () {
      final lyrics = [_lyric('君の名は'), _lyric('東京は晴れ')];
      expect(
        ZhConversion.shouldSkip(lyrics: lyrics, ignoredLanguages: const ['ja']),
        isTrue,
      );
      expect(
        ZhConversion.shouldSkip(
          lyrics: lyrics,
          ignoredLanguages: const ['ja'],
          languageHint: 'ja',
        ),
        isTrue,
      );
    });

    test('converts when the user removes Japanese from the ignore list', () {
      final lyrics = [_lyric('君の名は')];
      expect(
        ZhConversion.shouldSkip(lyrics: lyrics, ignoredLanguages: const []),
        isFalse,
      );
    });

    test('does not skip Chinese lyrics', () {
      final lyrics = [_lyric('简体中文歌词'), _lyric('副歌部分')];
      expect(
        ZhConversion.shouldSkip(lyrics: lyrics, ignoredLanguages: const ['ja']),
        isFalse,
      );
      // A single borrowed `の` is not Japanese.
      expect(
        ZhConversion.shouldSkip(
          lyrics: [_lyric('奈雪の茶')],
          ignoredLanguages: const ['ja'],
        ),
        isFalse,
      );
    });

    test('considers translations and inline parts', () {
      expect(
        ZhConversion.shouldSkip(
          lyrics: [_lyric('中文歌词', translation: '君の名は')],
          ignoredLanguages: const ['ja'],
        ),
        isTrue,
      );
      expect(
        ZhConversion.shouldSkip(
          lyrics: [
            _lyric(
              '中文歌词',
              parts: [
                LyricInlinePart(
                  startTime: Duration.zero,
                  endTime: const Duration(seconds: 1),
                  text: 'カタカナ',
                ),
              ],
            ),
          ],
          ignoredLanguages: const ['ja'],
        ),
        isTrue,
      );
    });
  });

  group('ZhConversion.convert', () {
    test('converts text, translation and inline parts', () {
      final converter = open(ZhConfig.s2twp);
      addTearDown(converter.dispose);

      final converted = ZhConversion.convert([
        _lyric(
          '软件里面',
          translation: '软件',
          parts: [
            LyricInlinePart(
              startTime: Duration.zero,
              endTime: const Duration(seconds: 1),
              text: '软件',
            ),
          ],
        ),
      ], converter: converter);

      expect(converted.first.text, '軟體裡面');
      expect(converted.first.translation, '軟體');
      expect(converted.first.inlineParts!.first.text, '軟體');
      expect(converted.first.startTime, Duration.zero);
    });

    test('returns the same list when nothing changes', () {
      final converter = open(ZhConfig.s2t);
      addTearDown(converter.dispose);

      final lyrics = [_lyric('hello world', translation: '12345')];
      expect(
        identical(ZhConversion.convert(lyrics, converter: converter), lyrics),
        isTrue,
      );
    });
  }, skip: skipReason);
}
