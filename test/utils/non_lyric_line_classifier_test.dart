import 'package:fluent_lyrics/utils/non_lyric_line_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isStructureMarker', () {
    test('matches English markers, bracketed or bare, with numbering', () {
      const markers = [
        'Verse 1',
        'verse',
        '[Chorus]',
        '(Chorus)',
        'Chorus:',
        'Pre-Chorus 2',
        'Pre Chorus',
        '[Verse II]',
        'Bridge',
        '[Intro]',
        'Outro',
        'Interlude',
        'Instrumental',
        'Chorus x2',
      ];
      for (final marker in markers) {
        expect(
          NonLyricLineClassifier.isStructureMarker(marker),
          isTrue,
          reason: '"$marker" should be a structure marker',
        );
      }
    });

    test('matches Chinese markers, bracketed or bare', () {
      const markers = ['主歌', '副歌', '【副歌】', '间奏', '間奏2', '尾奏', '过门'];
      for (final marker in markers) {
        expect(
          NonLyricLineClassifier.isStructureMarker(marker),
          isTrue,
          reason: '"$marker" should be a structure marker',
        );
      }
    });

    test('keeps real lyrics that merely contain or resemble a marker', () {
      const lyrics = [
        'London Bridge is falling down',
        '(ooh ooh)',
        '[啦啦啦]',
        'introduce yourself',
        'the chorus of frogs',
        '副歌一开始我就想起你',
        '',
      ];
      for (final line in lyrics) {
        expect(
          NonLyricLineClassifier.isStructureMarker(line),
          isFalse,
          reason: '"$line" should not be a structure marker',
        );
      }
    });
  });

  group('isCopyright', () {
    test('matches strong copyright notices in either script', () {
      const notices = [
        '未经许可，不得翻唱',
        '未經許可，不得翻唱',
        '版权所有',
        '保留所有权利',
        '侵权必究',
        'All Rights Reserved',
        '© 2024 Some Label',
      ];
      for (final notice in notices) {
        expect(
          NonLyricLineClassifier.isCopyright(notice),
          isTrue,
          reason: '"$notice" should be a copyright notice',
        );
      }
    });

    test('keeps ordinary lyrics', () {
      expect(NonLyricLineClassifier.isCopyright('I reserved a table'), isFalse);
      expect(NonLyricLineClassifier.isCopyright('版权是什么'), isFalse);
    });
  });
}
