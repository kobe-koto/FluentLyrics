import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/utils/lyrics_candidate_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Lyric lyric(String text, int seconds) {
    return Lyric(
      startTime: Duration(seconds: seconds),
      endTime: Duration(seconds: seconds + 1),
      text: text,
    );
  }

  LyricsResult result({
    required String source,
    List<Lyric> lyrics = const [],
    bool isSynced = false,
    bool translation = false,
    String? language,
    String? translationProvider,
  }) {
    return LyricsResult(
      lyrics: lyrics,
      source: source,
      isSynced: isSynced,
      translation: translation,
      language: language,
      translationProvider: translationProvider,
    );
  }

  test('matchesTranslationTargetLanguage compares case-insensitively', () {
    expect(matchesTranslationTargetLanguage(['zht', 'zh_CN'], 'ZH_cn'), isTrue);
    expect(matchesTranslationTargetLanguage(['zht'], 'ja'), isFalse);
  });

  test('appendTranslationCandidateIfNeeded skips duplicates', () {
    final existing = result(
      source: 'QQ Music',
      translation: true,
      language: 'zh_CN',
      translationProvider: 'QQ Music',
    );
    final candidates = [existing];

    final updated = appendTranslationCandidateIfNeeded(candidates, existing);

    expect(updated, same(candidates));
  });

  test('appendTranslationCandidateIfNeeded appends unique translations', () {
    final existing = result(
      source: 'QQ Music',
      translation: true,
      language: 'zh_CN',
      translationProvider: 'QQ Music',
    );
    final candidate = result(
      source: 'Netease Music',
      translation: true,
      language: 'zh_CN',
      translationProvider: 'Netease Music',
    );

    final updated = appendTranslationCandidateIfNeeded([existing], candidate);

    expect(updated, hasLength(2));
    expect(updated.last.translationProvider, 'Netease Music');
  });

  test('appendCandidateIfNeeded skips duplicate source/sync candidates', () {
    final existing = result(
      source: 'LRCLIB',
      lyrics: [lyric('hello', 1)],
      isSynced: true,
    );
    final candidates = [existing];

    final updated = appendCandidateIfNeeded(candidates, existing);

    expect(updated, same(candidates));
  });

  test('appendCandidateIfNeeded appends unique candidate', () {
    final existing = result(
      source: 'LRCLIB',
      lyrics: [lyric('hello', 1)],
      isSynced: true,
    );
    final candidate = result(
      source: 'QQ Music',
      lyrics: [lyric('hello', 1)],
      isSynced: true,
    );

    final updated = appendCandidateIfNeeded([existing], candidate);

    expect(updated, hasLength(2));
    expect(updated.last.source, 'QQ Music');
  });

  test('prepareLyricsResultForDisplay trims and prepends leading gap', () {
    final prepared = prepareLyricsResultForDisplay(
      LyricsResult(lyrics: [lyric('hello', 5)], source: 'LRCLIB'),
    );

    expect(prepared.lyrics, hasLength(2));
    expect(prepared.lyrics.first.text, '');
    expect(prepared.lyrics.first.startTime, Duration.zero);
    expect(prepared.lyrics.first.endTime, const Duration(seconds: 5));
    expect(prepared.lyrics.last.text, 'hello');
  });

  test('appendCandidateIfNeeded keeps a failure beside an unsynced result', () {
    final plain = LyricsResult(
      lyrics: [Lyric(startTime: Duration.zero, text: 'hello')],
      source: 'QQ Music',
      isSynced: false,
    );
    final failure = LyricsResult.failure(
      source: 'QQ Music',
      message: 'timed out',
    );

    final updated = appendCandidateIfNeeded([plain], failure);

    expect(updated, hasLength(2));
    expect(updated.last.failureMessage, 'timed out');
  });
}
