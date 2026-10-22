import 'dart:convert';

import 'package:xml/xml_events.dart';

/// Converts raw KANJIDIC2 XML into the trimmed kanji -> readings JSON the app
/// ships as an asset, matching `tool/kanji_readings_convert.py` so an
/// on-device download produces the same data as the build-time asset.
///
/// Only the Japanese on/kun readings (`ja_on`, `ja_kun`) are kept. Kun readings
/// are cut at the okurigana "." marker (た.べる -> た) and the "-" bound-form
/// markers are stripped, so readings are bare kana the splitter can match.
class KanjiReadingConverter {
  const KanjiReadingConverter._();

  /// A reading with its okurigana and bound-form markers removed.
  static String cleanReading(String value) {
    final dot = value.indexOf('.');
    final head = dot >= 0 ? value.substring(0, dot) : value;
    // Strip leading/trailing "-" (prefix/suffix bound forms), then whitespace.
    return head.replaceAll(RegExp(r'^-+|-+$'), '').trim();
  }

  /// Parses [xml] and returns the compact JSON string plus the KANJIDIC2
  /// version (`date_of_creation`, else `file_version`, else `unknown`).
  ///
  /// Uses the streaming event parser so the multi-megabyte file does not need
  /// a full DOM in memory on a phone.
  static ({String json, String version}) convert(String xml) {
    final readings = <String, List<String>>{};
    var version = 'unknown';

    String? literal;
    List<String>? current;
    Set<String>? seen;
    // The current text sink: which element's character data we are collecting.
    _Sink sink = _Sink.none;
    String? readingType;
    final buffer = StringBuffer();

    for (final event in parseEvents(xml)) {
      if (event is XmlStartElementEvent) {
        switch (event.name) {
          case 'character':
            literal = null;
            current = <String>[];
            seen = <String>{};
          case 'literal':
            buffer.clear();
            sink = _Sink.literal;
          case 'date_of_creation':
            buffer.clear();
            sink = _Sink.date;
          case 'file_version':
            buffer.clear();
            sink = _Sink.fileVersion;
          case 'reading':
            readingType = event.attributes
                .where((a) => a.name == 'r_type')
                .map((a) => a.value)
                .firstOrNull;
            if (readingType == 'ja_on' || readingType == 'ja_kun') {
              buffer.clear();
              sink = _Sink.reading;
            }
          default:
            break;
        }
        // Self-closing elements emit no end event.
        if (event.isSelfClosing) sink = _Sink.none;
      } else if (event is XmlTextEvent && sink != _Sink.none) {
        buffer.write(event.value);
      } else if (event is XmlCDATAEvent && sink != _Sink.none) {
        buffer.write(event.value);
      } else if (event is XmlEndElementEvent) {
        switch (event.name) {
          case 'literal':
            literal = buffer.toString().trim();
          case 'date_of_creation':
            final value = buffer.toString().trim();
            if (value.isNotEmpty) version = value;
          case 'file_version':
            final value = buffer.toString().trim();
            // date_of_creation wins; only use file_version if still unset.
            if (version == 'unknown' && value.isNotEmpty) version = value;
          case 'reading':
            if (sink == _Sink.reading) {
              final cleaned = cleanReading(buffer.toString());
              if (cleaned.isNotEmpty && seen!.add(cleaned)) {
                current!.add(cleaned);
              }
            }
          case 'character':
            if (literal != null &&
                literal.isNotEmpty &&
                current != null &&
                current.isNotEmpty) {
              readings[literal] = current;
            }
            literal = null;
            current = null;
            seen = null;
        }
        sink = _Sink.none;
      }
    }

    // Sort keys so the output is stable, matching the build-time script.
    // Sort keys so the output is stable across runs.
    final sortedKeys = readings.keys.toList()..sort();
    final ordered = <String, List<String>>{
      for (final key in sortedKeys) key: readings[key]!,
    };
    return (json: jsonEncode(ordered), version: version);
  }
}

enum _Sink { none, literal, date, fileVersion, reading }
