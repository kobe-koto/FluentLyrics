import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/services/winner_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Lyric lyric(String text, int milliseconds, {bool rich = false}) {
    return Lyric(
      startTime: Duration(milliseconds: milliseconds),
      endTime: Duration(milliseconds: milliseconds + 1000),
      text: text,
      inlineParts: rich
          ? [
              LyricInlinePart(
                startTime: Duration(milliseconds: milliseconds),
                endTime: Duration(milliseconds: milliseconds + 500),
                text: text,
              ),
            ]
          : null,
    );
  }

  LyricsResult result({
    required String source,
    List<Lyric> lyrics = const [],
    bool isPureMusic = false,
    List<String>? artworkUrls,
  }) {
    return LyricsResult(
      lyrics: lyrics,
      source: source,
      isPureMusic: isPureMusic,
      artworkUrls: artworkUrls,
    );
  }

  test('returns candidate when there is no current best', () {
    final candidate = result(
      source: 'QQ Music',
      lyrics: [lyric('hello', 1000)],
      artworkUrls: ['cover-a'],
    );

    final selected = selectBetterCandidate(candidate, null, true);

    expect(selected?.source, 'QQ Music');
    expect(selected?.lyrics.length, 1);
    expect(selected?.artworkUrls, ['cover-a']);
  });

  test('keeps non-instrumental best over pure music candidate', () {
    final best = result(source: 'LRCLIB', lyrics: [lyric('hello', 1000)]);
    final candidate = result(source: 'Musixmatch', isPureMusic: true);

    final selected = selectBetterCandidate(candidate, best, true);

    expect(selected, same(best));
  });

  test('prefers candidate with lyrics when current best is empty', () {
    final best = result(source: 'Cache');
    final candidate = result(
      source: 'Netease Music',
      lyrics: [lyric('hello', 1000)],
    );

    final selected = selectBetterCandidate(candidate, best, true);

    expect(selected?.source, 'Netease Music');
    expect(selected?.lyrics.length, 1);
  });

  test('prefers rich sync candidate when rich sync is enabled', () {
    final best = result(source: 'QQ Music', lyrics: [lyric('plain', 1000)]);
    final candidate = result(
      source: 'Musixmatch',
      lyrics: [lyric('rich', 1000, rich: true)],
    );

    final selected = selectBetterCandidate(candidate, best, true);

    expect(selected?.source, 'Musixmatch');
    expect(selected?.isRichSync, isTrue);
  });

  test('keeps current best when both sit at the same sync tier even if '
      'candidate has more artwork URLs', () {
    final best = result(
      source: 'LRCLIB',
      lyrics: [lyric('hello', 1000)],
      artworkUrls: ['cover-a'],
    );
    final candidate = result(
      source: 'QQ Music',
      lyrics: [lyric('hello', 1000)],
      artworkUrls: ['cover-a', 'cover-b'],
    );

    final selected = selectBetterCandidate(candidate, best, true);

    expect(selected, same(best));
    expect(selected?.artworkUrls?.length, 1);
  });

  test('treats rich sync result as good enough when rich sync is enabled', () {
    final best = result(
      source: 'Musixmatch',
      lyrics: [lyric('rich', 1000, rich: true)],
    );

    final isGoodEnough = hasGoodEnoughLyricsResult(best, true, false, false);

    expect(isGoodEnough, isTrue);
  });

  test(
    'requires translation before early exit when translation is enabled',
    () {
      final best = result(source: 'QQ Music', lyrics: [lyric('hello', 1000)]);

      final isGoodEnough = hasGoodEnoughLyricsResult(best, false, true, false);

      expect(isGoodEnough, isFalse);
    },
  );

  test(
    'accepts pure music result as good enough after translation arrives',
    () {
      final best = result(source: 'LRCLIB', isPureMusic: true);

      final isGoodEnough = hasGoodEnoughLyricsResult(best, true, true, true);

      expect(isGoodEnough, isTrue);
    },
  );
}
