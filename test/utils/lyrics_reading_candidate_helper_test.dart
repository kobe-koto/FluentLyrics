import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/utils/lyrics_reading_candidate_helper.dart';
import 'package:flutter_test/flutter_test.dart';

LyricsReading _romajiReading(int lineCount, {String text = 'shi zu mu'}) =>
    LyricsReading(
      lineType: LyricsReadingType.romaji,
      lines: [
        for (var i = 0; i < lineCount; i++)
          Lyric(
            startTime: Duration(seconds: i),
            text: text,
          ),
      ],
    );

void main() {
  test('appends a reading track that is not present yet', () {
    final candidates = appendReadingCandidateIfNeeded(
      const [],
      _romajiReading(2),
    );
    expect(candidates, hasLength(1));
  });

  test('ignores duplicates of the same track', () {
    final first = appendReadingCandidateIfNeeded(const [], _romajiReading(2));
    final second = appendReadingCandidateIfNeeded(first, _romajiReading(2));
    expect(identical(first, second), isTrue);
  });

  test('keeps tracks of a different script or shape', () {
    final candidates = appendReadingCandidateIfNeeded(
      appendReadingCandidateIfNeeded(const [], _romajiReading(2)),
      LyricsReading(
        lineType: LyricsReadingType.kana,
        lines: [Lyric(startTime: Duration.zero, text: 'しずむ')],
      ),
    );
    expect(candidates, hasLength(2));

    final longer = appendReadingCandidateIfNeeded(
      candidates,
      _romajiReading(3),
    );
    expect(longer, hasLength(3));
  });

  test('ignores empty readings', () {
    expect(
      appendReadingCandidateIfNeeded(const [], const LyricsReading()),
      isEmpty,
    );
  });
}
