import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_lyrics/utils/rich_lrc_parser.dart';

void main() {
  group('QQRichParser', () {
    test('parses a plain line with no literal parens', () {
      const content = '[1000,500]hello (1000,200)world (1200,300)';
      final lyrics = QQRichParser.parse(content);

      expect(lyrics, hasLength(1));
      final line = lyrics.single;
      expect(line.startTime.inMilliseconds, 1000);
      expect(line.endTime!.inMilliseconds, 1500);
      expect(line.text, 'hello world ');
      expect(line.inlineParts!.map((p) => p.text).toList(), [
        'hello ',
        'world ',
      ]);
      expect(line.inlineParts![0].startTime.inMilliseconds, 1000);
      expect(line.inlineParts![0].endTime.inMilliseconds, 1200);
      expect(line.inlineParts![1].startTime.inMilliseconds, 1200);
      expect(line.inlineParts![1].endTime.inMilliseconds, 1500);
    });

    test(
      'preserves literal parentheses in lyric text — '
      'regression for "Mastered (...)by：권남우 ((..)Asst. (..)유은진)"',
      () {
        const content =
            '[3773,19]Mastered (3773,3)by：권남우 ((3776,3)Asst. (3779,3)유은진) @ (3782,3)821 (3785,3)Sound';

        final lyrics = QQRichParser.parse(content);
        expect(lyrics, hasLength(1));
        final line = lyrics.single;

        // All literal characters from the source line must survive.
        expect(
          line.text,
          'Mastered by：권남우 (Asst. 유은진) @ 821 Sound',
        );

        // Five timestamps → five inline parts.
        final parts = line.inlineParts!;
        expect(parts, hasLength(5));

        // Each part's text matches what is to its left in source order.
        expect(parts[0].text, 'Mastered ');
        expect(parts[1].text, 'by：권남우 (');
        expect(parts[2].text, 'Asst. ');
        expect(parts[3].text, '유은진) @ ');
        // Last part absorbs trailing "Sound" with no timestamp of its own.
        expect(parts[4].text, '821 Sound');

        // Sanity: timings come from the timestamps in source order.
        expect(parts[0].startTime.inMilliseconds, 3773);
        expect(parts[0].endTime.inMilliseconds, 3776);
        expect(parts[4].startTime.inMilliseconds, 3785);
      },
    );

    test('keeps a trailing word that has no timestamp attached', () {
      const content = '[100,400]foo (100,100)bar (200,100)baz';
      final lyrics = QQRichParser.parse(content);

      final parts = lyrics.single.inlineParts!;
      expect(parts, hasLength(2));
      expect(parts[0].text, 'foo ');
      // "baz" must end up appended to the last timed part.
      expect(parts[1].text, 'bar baz');
      expect(lyrics.single.text, 'foo bar baz');
    });

    test(
      'falls back to plain text when a line has no timestamps at all',
      () {
        const content = '[100,400]some metadata line with no timing markers';
        final lyrics = QQRichParser.parse(content);
        expect(lyrics, hasLength(1));
        final line = lyrics.single;
        expect(line.inlineParts, isNull);
        expect(line.text, 'some metadata line with no timing markers');
      },
    );

    test('skips lines that do not start with a [line-header]', () {
      const content = 'not a real line\n[10,100]hi (10,50)there (60,50)';
      final lyrics = QQRichParser.parse(content);
      expect(lyrics, hasLength(1));
      expect(lyrics.single.text, 'hi there ');
    });

    test('handles empty input safely', () {
      expect(QQRichParser.parse(''), isEmpty);
      expect(QQRichParser.parse('\n\n  \n'), isEmpty);
    });

    test(
      'preserves text containing a CJK fullwidth left paren that should not '
      'be confused with a timestamp delimiter',
      () {
        // Fullwidth `（` is not part of the timestamp grammar and must be
        // treated as plain text.
        const content = '[0,1000]主唱（仅一句）：A (0,500)然后 B (500,500)';
        final lyrics = QQRichParser.parse(content);
        expect(lyrics.single.text, '主唱（仅一句）：A 然后 B ');
      },
    );
  });
}
