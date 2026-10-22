import 'dart:convert';
import 'dart:io';

import 'package:fluent_lyrics/services/kanji_reading_dictionary.dart';
import 'package:flutter_test/flutter_test.dart';

const _xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kanjidic2>
  <header><date_of_creation>2026-11-01</date_of_creation></header>
  <character>
    <literal>勇</literal>
    <reading_meaning><rmgroup>
      <reading r_type="ja_on">ユウ</reading>
      <reading r_type="ja_kun">いさ.む</reading>
    </rmgroup></reading_meaning>
  </character>
  <character>
    <literal>気</literal>
    <reading_meaning><rmgroup>
      <reading r_type="ja_on">キ</reading>
      <reading r_type="ja_on">ケ</reading>
      <reading r_type="ja_on">いき</reading>
      <reading r_type="ja_kun">き</reading>
    </rmgroup></reading_meaning>
  </character>
</kanjidic2>
''';

void main() {
  late Directory tempDir;
  final dict = KanjiReadingDictionary.instance;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kanji_dict_test');
    dict.reset();
    dict.httpGetBytes = (uri) async => gzip.encode(utf8.encode(_xml));
  });

  tearDown(() {
    dict.reset();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('downloads, converts, and installs the dictionary', () async {
    final version = await dict.downloadFromEdrdg(directory: tempDir);
    expect(version, '2026-11-01');
    expect(dict.installedVersion, '2026-11-01');

    final dataFile = File('${tempDir.path}/kanji_readings.json');
    final marker = File('${tempDir.path}/version.txt');
    expect(dataFile.existsSync(), isTrue);
    expect(marker.readAsStringSync().trim(), '2026-11-01');

    final decoded =
        jsonDecode(dataFile.readAsStringSync()) as Map<String, dynamic>;
    expect(decoded['勇'], ['ユウ', 'いさ']);
  });

  test('the installed splitter splits a compound per kanji', () async {
    await dict.downloadFromEdrdg(directory: tempDir);
    final splitter = await dict.splitter(directory: tempDir);
    expect(splitter, isNotNull);

    final parts = splitter!.split(text: '勇気', start: 0, end: 2, reading: 'ゆうき');
    expect(parts, isNotNull);
    expect(parts!.map((p) => p.reading).toList(), ['ゆう', 'き']);
  });

  test('a failed download keeps the previous copy and returns null', () async {
    // Install once, then make the next download throw.
    await dict.downloadFromEdrdg(directory: tempDir);
    dict.httpGetBytes = (uri) async => throw const SocketException('offline');

    final version = await dict.downloadFromEdrdg(directory: tempDir);
    expect(version, isNull);
    // The previously installed data file is untouched.
    expect(File('${tempDir.path}/kanji_readings.json').existsSync(), isTrue);
  });

  test('corrupt (non-gzip) response fails without writing', () async {
    dict.httpGetBytes = (uri) async => utf8.encode('not gzip');
    final version = await dict.downloadFromEdrdg(directory: tempDir);
    expect(version, isNull);
    expect(File('${tempDir.path}/kanji_readings.json').existsSync(), isFalse);
  });
}
