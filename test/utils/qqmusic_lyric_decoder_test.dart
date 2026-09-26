import 'package:fluent_lyrics/utils/qqmusic_lyric_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const encryptedHello =
      '32dabb4c5e9846fa7a4eb4ea8db4d7fe7b53bcbf3bd277187eb1ac1aa01173d7c56db7284fe2b535';

  test('decrypts a QRC payload inside a lyric download response', () {
    final decoded = QQMusicLyricDecoder.parseLyricDownloadResponse(
      '<content>$encryptedHello</content>',
    );

    expect(decoded?.lyric, '[00:01.00]hello\n[00:02.00]world');
    expect(decoded?.trans, isNull);
    expect(decoded?.roma, isNull);
  });

  test('decrypts LyricContent nested in an escaped content tag', () {
    final decoded = QQMusicLyricDecoder.parseLyricDownloadResponse('''
<!--
<QrcInfos miniversion="1">
<content>&lt;Lyric_1 LyricContent="$encryptedHello" /&gt;</content>
<contentts>[00:01.00]你好</contentts>
<contentroma>[00:01.00]ni hao</contentroma>
</QrcInfos>
-->
''');

    expect(decoded?.lyric, '[00:01.00]hello\n[00:02.00]world');
    expect(decoded?.trans, '[00:01.00]你好');
    expect(decoded?.roma, '[00:01.00]ni hao');
  });

  test('reads plain lyrics and strips CDATA', () {
    final decoded = QQMusicLyricDecoder.parseLyricDownloadResponse(
      '<content><![CDATA[[00:03.00]plain]]></content>',
    );

    expect(decoded?.lyric, '[00:03.00]plain');
  });

  test('repairs utf-8 that was decoded as latin1', () {
    final decoded = QQMusicLyricDecoder.parseLyricDownloadResponse(
      '<content>ä½\u00a0å¥½</content>',
    );

    expect(decoded?.lyric, '你好');
  });

  test('returns null when every lyric field is blank', () {
    expect(
      QQMusicLyricDecoder.parseLyricDownloadResponse(
        '<content>   </content><contentts></contentts>',
      ),
      isNull,
    );
    expect(QQMusicLyricDecoder.parseLyricDownloadResponse(''), isNull);
  });

  test('a failed decrypt does not throw or invent timed lyrics', () {
    final decoded = QQMusicLyricDecoder.parseLyricDownloadResponse(
      '<content>abcd</content>',
    );

    expect(decoded?.lyric ?? '', isNot(contains('[')));
  });
}
