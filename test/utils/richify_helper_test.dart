import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/utils/richify_helper.dart';

LyricInlinePart _part(int startMs, int endMs, String text) => LyricInlinePart(
  startTime: Duration(milliseconds: startMs),
  endTime: Duration(milliseconds: endMs),
  text: text,
);

Lyric _line(
  int startMs,
  String text, {
  int? endMs,
  List<LyricInlinePart>? parts,
  String? translation,
}) => Lyric(
  startTime: Duration(milliseconds: startMs),
  endTime: endMs != null ? Duration(milliseconds: endMs) : null,
  text: text,
  inlineParts: parts,
  translation: translation,
);

LyricsResult _result({
  required List<Lyric> lyrics,
  String source = 'test',
}) => LyricsResult(lyrics: lyrics, source: source);

void main() {
  group('RichifyHelper.apply — text fidelity', () {
    test('drops source-only trailing comma and keeps target text', () {
      // src has "hello," split across two parts; target is "hello".
      final src = _result(
        lyrics: [
          _line(
            1000,
            'hello,',
            endMs: 1500,
            parts: [
              _part(1000, 1400, 'hello'),
              _part(1400, 1500, ','),
            ],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(1000, 'hello', endMs: 1500)],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      expect(out.isRichSync, isTrue);
      expect(out.lyrics.single.text, 'hello');
      // Rendered text must come only from target.
      final partsText =
          out.lyrics.single.inlineParts!.map((p) => p.text).join();
      expect(partsText, 'hello');
      // The comma part timing got dropped; we should be left with 1 part.
      expect(out.lyrics.single.inlineParts!.length, 1);
    });

    test('keeps target-only punctuation by attaching to neighbouring part', () {
      // Source has plain "hello world"; target adds a comma.
      final src = _result(
        lyrics: [
          _line(
            0,
            'hello world',
            endMs: 1000,
            parts: [
              _part(0, 400, 'hello'),
              _part(400, 500, ' '),
              _part(500, 1000, 'world'),
            ],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(0, 'hello, world', endMs: 1000)],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      expect(out.lyrics.single.text, 'hello, world');
      final partsText =
          out.lyrics.single.inlineParts!.map((p) => p.text).join();
      // No characters lost — the extra comma rides along.
      expect(partsText, 'hello, world');
    });

    test('preserves case from target even if source differs', () {
      final src = _result(
        lyrics: [
          _line(
            0,
            'HELLO',
            endMs: 500,
            parts: [_part(0, 250, 'HEL'), _part(250, 500, 'LO')],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(0, 'hello', endMs: 500)],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      final partsText =
          out.lyrics.single.inlineParts!.map((p) => p.text).join();
      expect(partsText, 'hello'); // target casing preserved
      // Still two parts because the source had two parts.
      expect(out.lyrics.single.inlineParts!.length, 2);
    });

    test('folds CJK fullwidth comma to ASCII comma when aligning', () {
      final src = _result(
        lyrics: [
          _line(
            0,
            '你好，世界',
            endMs: 1000,
            parts: [
              _part(0, 200, '你'),
              _part(200, 400, '好'),
              _part(400, 500, '，'),
              _part(500, 750, '世'),
              _part(750, 1000, '界'),
            ],
          ),
        ],
      );
      // Target uses ASCII comma instead of fullwidth.
      final target = _result(
        lyrics: [_line(0, '你好,世界', endMs: 1000)],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      expect(out.lyrics.single.text, '你好,世界');
      final partsText =
          out.lyrics.single.inlineParts!.map((p) => p.text).join();
      expect(partsText, '你好,世界');
    });

    test('aborts richify for one line when source text is unrelated', () {
      final src = _result(
        lyrics: [
          _line(
            0,
            'completely different lyrics here',
            endMs: 1000,
            parts: [
              _part(0, 500, 'completely different'),
              _part(500, 1000, 'lyrics here'),
            ],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(0, 'abc', endMs: 1000)],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      // No good alignment → richCount==0 → result stays plain.
      expect(out.lyrics.single.inlineParts, isNull);
      expect(out.isRichSync, isFalse);
    });
  });

  group('RichifyHelper.apply — timing', () {
    test('re-anchors timing by line offset', () {
      final src = _result(
        lyrics: [
          _line(
            500,
            'hi',
            endMs: 1500,
            parts: [_part(500, 1000, 'h'), _part(1000, 1500, 'i')],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(2000, 'hi', endMs: 3000)],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      final parts = out.lyrics.single.inlineParts!;
      expect(parts.first.startTime.inMilliseconds, 2000);
      expect(parts.last.endTime.inMilliseconds, 3000);
    });

    test('clamps part timings inside the target line bounds', () {
      // Source ends past where target ends.
      final src = _result(
        lyrics: [
          _line(
            0,
            'hi',
            endMs: 5000,
            parts: [_part(0, 2500, 'h'), _part(2500, 5000, 'i')],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(0, 'hi', endMs: 1000)],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      final parts = out.lyrics.single.inlineParts!;
      for (final p in parts) {
        expect(p.endTime.inMilliseconds, lessThanOrEqualTo(1000));
        expect(p.startTime.inMilliseconds, lessThanOrEqualTo(1000));
      }
    });

    test('keeps monotonic part start times', () {
      final src = _result(
        lyrics: [
          _line(
            0,
            'abc',
            endMs: 900,
            parts: [
              _part(0, 300, 'a'),
              _part(300, 600, 'b'),
              _part(600, 900, 'c'),
            ],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(0, 'abc', endMs: 900)],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      final parts = out.lyrics.single.inlineParts!;
      for (int i = 1; i < parts.length; i++) {
        expect(
          parts[i].startTime >= parts[i - 1].startTime,
          isTrue,
          reason: 'parts must be monotonic',
        );
      }
    });
  });

  group('RichifyHelper.apply — line matching strategies', () {
    test('matches by exact timestamp first', () {
      final src = _result(
        lyrics: [
          _line(
            500,
            'wrong text',
            endMs: 1500,
            parts: [_part(500, 1500, 'wrong text')],
          ),
          _line(
            1000,
            'hello world',
            endMs: 2000,
            parts: [
              _part(1000, 1500, 'hello'),
              _part(1500, 2000, 'world'),
            ],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(1000, 'hello world', endMs: 2000)],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      expect(out.lyrics.single.inlineParts!.length, greaterThanOrEqualTo(1));
      // Should have aligned onto the second source line via exact timestamp,
      // not the first; rendered text follows target.
      final txt = out.lyrics.single.inlineParts!.map((p) => p.text).join();
      expect(txt, 'hello world');
    });

    test('skips blank lines without richifying them', () {
      final src = _result(
        lyrics: [
          _line(
            0,
            'hello',
            endMs: 500,
            parts: [_part(0, 500, 'hello')],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(0, '', endMs: 500), _line(500, 'hello', endMs: 1000)],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      expect(out.lyrics.first.inlineParts, isNull);
      expect(out.lyrics.last.inlineParts, isNotNull);
    });
  });

  group('RichifyHelper.apply — translation preservation', () {
    test('target translation survives richify', () {
      final src = _result(
        lyrics: [
          _line(
            0,
            'hello',
            endMs: 500,
            parts: [_part(0, 500, 'hello')],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(0, 'hello', endMs: 500, translation: '你好')],
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      expect(out.lyrics.single.translation, '你好');
    });
  });

  group('RichifyHelper.apply — global flags', () {
    test('marks result as rich-synced and tags the source string', () {
      final src = _result(
        lyrics: [
          _line(
            0,
            'hi',
            endMs: 500,
            parts: [_part(0, 250, 'h'), _part(250, 500, 'i')],
          ),
        ],
        source: 'Musixmatch (rich)',
      );
      final target = _result(
        lyrics: [_line(0, 'hi', endMs: 500)],
        source: 'lrclib',
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      expect(out.isRichSync, isTrue);
      expect(out.source.contains('lrclib'), isTrue);
      expect(out.source.contains('Richified'), isTrue);
    });

    test('returns source unchanged when nothing aligned', () {
      final src = _result(
        lyrics: [
          _line(
            0,
            'aaaaaaaa',
            endMs: 500,
            parts: [_part(0, 500, 'aaaaaaaa')],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(10000, 'xyz', endMs: 11000)],
        source: 'lrclib',
      );

      final out = RichifyHelper.apply(syncedTarget: target, richSource: src);
      expect(out.isRichSync, isFalse);
      expect(out.source, 'lrclib');
    });
  });

  group('RichifyHelper.coverage', () {
    test('returns 1.0 when every line matches', () {
      final src = _result(
        lyrics: [
          _line(
            0,
            'hello',
            endMs: 500,
            parts: [_part(0, 500, 'hello')],
          ),
          _line(
            500,
            'world',
            endMs: 1000,
            parts: [_part(500, 1000, 'world')],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(0, 'hello', endMs: 500), _line(500, 'world', endMs: 1000)],
      );

      expect(
        RichifyHelper.coverage(syncedTarget: target, richSource: src),
        1.0,
      );
    });

    test('returns 0 when target has only blank content', () {
      final src = _result(
        lyrics: [
          _line(
            0,
            'hello',
            endMs: 500,
            parts: [_part(0, 500, 'hello')],
          ),
        ],
      );
      final target = _result(
        lyrics: [_line(0, '   ', endMs: 500)],
      );

      expect(
        RichifyHelper.coverage(syncedTarget: target, richSource: src),
        0,
      );
    });
  });
}
