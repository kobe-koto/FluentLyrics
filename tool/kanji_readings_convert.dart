// Build-time CLI that converts raw KANJIDIC2 XML into the trimmed kanji ->
// readings JSON shipped as an asset. It imports the same conversion logic the
// app uses at runtime (lib/utils/kanji_readings_converter.dart) so the
// build-time asset and an in-app EDRDG download produce byte-identical data.
//
// Invoked by tool/sync_kanji_readings.sh:
//   dart run tool/kanji_readings_convert.dart \
//     --input <xml> --out-json <json> --out-version <txt>

import 'dart:convert';
import 'dart:io';

import 'package:fluent_lyrics/utils/kanji_readings_converter.dart';

void main(List<String> args) {
  final options = _parseArgs(args);
  final xml = File(options['input']!).readAsStringSync();
  final result = KanjiReadingConverter.convert(xml);

  File(options['out-json']!).writeAsStringSync(result.json);
  File(options['out-version']!).writeAsStringSync('${result.version}\n');

  final count = (jsonDecode(result.json) as Map<String, dynamic>).length;
  stdout.writeln('Wrote $count kanji (${result.version})');
}

Map<String, String> _parseArgs(List<String> args) {
  final options = <String, String>{};
  for (var i = 0; i < args.length - 1; i += 2) {
    final key = args[i];
    if (!key.startsWith('--')) {
      stderr.writeln('error: unexpected argument "$key"');
      exit(2);
    }
    options[key.substring(2)] = args[i + 1];
  }
  for (final required in ['input', 'out-json', 'out-version']) {
    if (!options.containsKey(required)) {
      stderr.writeln('error: missing --$required');
      exit(2);
    }
  }
  return options;
}
