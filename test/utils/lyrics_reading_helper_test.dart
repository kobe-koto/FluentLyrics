import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/utils/lyrics_reading_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LyricsReadingHelper.fromNeteasePayload', () {
    test('prefers the kana track when it is not empty', () {
      final reading = LyricsReadingHelper.fromNeteasePayload({
        'klyric': {'lyric': '[00:01.430]きみのなは\n[00:02.000]とうきょう'},
        'romalrc': {'lyric': '[00:01.430]ki mi no na wa'},
      });

      expect(reading, isNotNull);
      expect(reading!.lineType, LyricsReadingType.kana);
      expect(reading.lines, hasLength(2));
      expect(reading.lines.first.text, 'きみのなは');
      expect(reading.lines.first.startTime, const Duration(milliseconds: 1430));
    });

    test('falls back to the romanized track (kana is usually empty)', () {
      final reading = LyricsReadingHelper.fromNeteasePayload({
        'klyric': {'lyric': ''},
        'romalrc': {
          'lyric':
              '[00:01.430]shi zu mu yo u ni\n[00:08.831]fu ta ri da ke no so ra ga',
        },
      });

      expect(reading, isNotNull);
      expect(reading!.lineType, LyricsReadingType.romaji);
      expect(reading.lines, hasLength(2));
      expect(reading.lines.last.text, 'fu ta ri da ke no so ra ga');
      expect(reading.lines.last.startTime, const Duration(milliseconds: 8831));
    });

    test('returns null when the provider ships no reading track', () {
      expect(LyricsReadingHelper.fromNeteasePayload({}), isNull);
      expect(
        LyricsReadingHelper.fromNeteasePayload({
          'klyric': {'lyric': ''},
          'romalrc': {'lyric': '   '},
        }),
        isNull,
      );
    });
  });

  group('LyricsReadingHelper.fromQqPayload', () {
    // QQ serves word level QRC: [lineStartMs,lineDurationMs](wordMs,dur)word...
    const roma =
        '[1800,7400]shi (1800,231)zu (2032,240)mu (2273,420)yo (2693,261)u (2955,261)ni (3217,223)to\n'
        '[9201,1100]ki (9201,192)mi (9393,258)no (9651,198)na (9849,228)wa';

    test('parses the romanized track into line level readings', () {
      final reading = LyricsReadingHelper.fromQqPayload(roma: roma);

      expect(reading, isNotNull);
      expect(reading!.lineType, LyricsReadingType.romaji);
      expect(reading.lines, hasLength(2));
      expect(reading.lines.first.startTime, const Duration(milliseconds: 1800));
      expect(reading.lines.first.text.replaceAll(' ', ''), 'shizumuyounito');
      expect(reading.lines.last.startTime, const Duration(milliseconds: 9201));
    });

    test('extracts the word level kana payload from the lyric track', () {
      const lyric =
          '[ti:Test]\n'
          '[kana:1よる1か1し1きょく1しず1と1ふ(9201,192)た(9393,258)1り1そら]\n'
          '[0,946]夜(0,236)に(237,118)';

      final reading = LyricsReadingHelper.fromQqPayload(
        lyric: lyric,
        roma: roma,
      );

      expect(reading, isNotNull);
      expect(reading!.kanaRaw, startsWith('1よる1か1し1きょく1しず'));
      expect(reading.kanaRaw, endsWith('1り1そら'));
    });

    test('keeps the kana payload even without a romanized track', () {
      const lyric = '[kana:1よる1か1し1きょく]\n[0,946]夜(0,236)に(237,118)';

      final reading = LyricsReadingHelper.fromQqPayload(lyric: lyric);

      expect(reading, isNotNull);
      expect(reading!.lines, isEmpty);
      expect(reading.lineType, isNull);
      expect(reading.kanaRaw, '1よる1か1し1きょく');
    });

    test('accepts plain LRC readings and ignores missing payloads', () {
      final lrc = LyricsReadingHelper.fromQqPayload(
        roma: '[00:01.800]shi zu mu yo u ni',
      );
      expect(lrc!.lineType, LyricsReadingType.romaji);
      expect(lrc.lines.single.text, 'shi zu mu yo u ni');

      expect(LyricsReadingHelper.fromQqPayload(), isNull);
      expect(LyricsReadingHelper.fromQqPayload(roma: '   '), isNull);
    });

    test('does not treat empty kana metadata as a reading', () {
      expect(
        LyricsReadingHelper.extractQqKanaMetadata('[kana:]\n[0,946]夜(0,236)'),
        isNull,
      );
      expect(LyricsReadingHelper.extractQqKanaMetadata(null), isNull);
      expect(LyricsReadingHelper.extractQqKanaMetadata('[ti:Test]'), isNull);
    });
  });

  group('LyricsReading serialization', () {
    test('round trips through LyricsResult json', () {
      final result = LyricsResult(
        lyrics: [Lyric(startTime: Duration.zero, text: '沈むように')],
        source: 'test',
        reading: LyricsReading(
          lineType: LyricsReadingType.romaji,
          lines: [
            Lyric(startTime: Duration(milliseconds: 1430), text: 'shi zu mu'),
          ],
          kanaRaw: '1しず1む',
        ),
      );

      final restored = LyricsResult.fromJson(result.toJson());

      expect(restored.reading, isNotNull);
      expect(restored.reading!.lineType, LyricsReadingType.romaji);
      expect(restored.reading!.lines.single.text, 'shi zu mu');
      expect(
        restored.reading!.lines.single.startTime,
        const Duration(milliseconds: 1430),
      );
      expect(restored.reading!.kanaRaw, '1しず1む');
    });

    test('omits the reading when there is none', () {
      final result = LyricsResult(
        lyrics: [Lyric(startTime: Duration.zero, text: 'line')],
        source: 'test',
      );
      expect(result.toJson().containsKey('reading'), isFalse);
      expect(LyricsResult.fromJson(result.toJson()).reading, isNull);
    });
  });

  group('LyricsReadingHelper.pairReadings', () {
    List<Lyric> lines(List<(int, String)> entries) => [
      for (final (ms, text) in entries)
        Lyric(
          startTime: Duration(milliseconds: ms),
          text: text,
        ),
    ];

    test('pairs by exact timestamp first', () {
      final paired = LyricsReadingHelper.pairReadings(
        lines([(0, 'a'), (1000, 'b')]),
        lines([(0, 'A'), (1000, 'B')]),
      );
      expect(paired, ['A', 'B']);
    });

    test('falls back to the nearest line inside the tolerance', () {
      // QQ serves the reading from the word level payload: line starts drift.
      final paired = LyricsReadingHelper.pairReadings(
        lines([(0, 'a'), (1000, 'b'), (2000, 'c')]),
        lines([(30, 'A'), (1120, 'B'), (1890, 'C')]),
      );
      expect(paired, ['A', 'B', 'C']);
    });

    test('falls back to positions when the track has the same length', () {
      final paired = LyricsReadingHelper.pairReadings(
        lines([(0, 'a'), (5000, 'b')]),
        lines([(900, 'A'), (9000, 'B')]),
      );
      expect(paired, ['A', 'B']);
    });

    test('leaves lines without a plausible reading unpaired', () {
      final paired = LyricsReadingHelper.pairReadings(
        lines([(0, 'a'), (10000, 'b')]),
        lines([(0, 'A')]),
      );
      expect(paired, ['A', null]);
    });
  });
}
