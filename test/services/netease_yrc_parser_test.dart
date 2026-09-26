import 'package:fluent_lyrics/services/providers/netease_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses word timings and a line without word tags', () {
    final lyrics = NeteaseYrcParser.parse('''
[1000,1800](1000,400,0)hel(1400,500,0)lo
[3000,500]just text
''');

    expect(lyrics, hasLength(2));
    expect(lyrics[0].text, 'hello');
    expect(lyrics[0].startTime, const Duration(milliseconds: 1000));
    expect(lyrics[0].endTime, const Duration(milliseconds: 2800));
    expect(lyrics[0].inlineParts!.map((part) => part.text), ['hel', 'lo']);
    expect(
      lyrics[0].inlineParts![0].endTime,
      const Duration(milliseconds: 1400),
    );
    expect(lyrics[1].text, 'just text');
    expect(lyrics[1].inlineParts, isNull);
  });
}
