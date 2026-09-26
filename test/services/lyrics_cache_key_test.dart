import 'package:fluent_lyrics/services/providers/lyrics_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = LyricsCacheService();

  test('lyric cache ids include album, duration, and rich or standard', () {
    expect(
      service.generateCacheId('Song', const ['Artist', 'Guest'], null, 120),
      'df76b9fe7c0cf77046e13b2c3fdb9d58fe5cbf10f3f385493689b92083c1ff30_std',
    );
    expect(
      service.generateCacheId(
        'Song',
        const ['Artist', 'Guest'],
        'Album',
        90,
        isRichSync: true,
      ),
      '678d47b8ab4bac8deb0af4b3f2f16d9ecc3cc1a099168916f1b385cfd38fa8d1_rich',
    );
    expect(
      service.generateCacheId('Song', const ['Artist', 'Guest'], '', 120),
      service.generateCacheId('Song', const ['Artist', 'Guest'], null, 120),
    );
    expect(
      service.generateCacheId('Song', const ['Guest', 'Artist'], null, 120),
      isNot(
        service.generateCacheId('Song', const ['Artist', 'Guest'], null, 120),
      ),
    );
  });

  test('translation cache ids ignore album and duration', () {
    expect(
      service.generateTranslationCacheId('Song', const [
        'Artist',
        'Guest',
      ], 'zht'),
      '3ff4bad44e358805956db1a6692251ee05a500cb180244ed8224f4c2cef26f38',
    );
    expect(
      service.generateTranslationCacheId('Song', const [
        'Artist',
        'Guest',
      ], 'zh_CN'),
      isNot(
        service.generateTranslationCacheId('Song', const [
          'Artist',
          'Guest',
        ], 'zht'),
      ),
    );
  });
}
