import 'dart:convert';
import 'dart:io';

import 'package:html_unescape/html_unescape.dart';

import '../models/lyric_model.dart';
import 'app_logger.dart';

/// Parser for Kugou's encrypted KRC lyric format.
class KrcParser {
  static const _header = [0x6b, 0x72, 0x63, 0x31]; // krc1
  static const _key = [
    0x40,
    0x47,
    0x61,
    0x77,
    0x5e,
    0x32,
    0x74,
    0x47,
    0x51,
    0x36,
    0x31,
    0x2d,
    0xce,
    0xd2,
    0x6e,
    0x69,
  ];

  static List<Lyric> parse(String content) {
    try {
      final bytes = base64.decode(content);
      if (bytes.length < _header.length ||
          !_header.asMap().entries.every(
            (entry) => bytes[entry.key] == entry.value,
          )) {
        return [];
      }

      final encrypted = bytes.sublist(_header.length);
      final decoded = List<int>.generate(
        encrypted.length,
        (index) => encrypted[index] ^ _key[index % _key.length],
      );
      final text = utf8.decode(ZLibCodec().decode(decoded));
      return _parseText(text);
    } catch (error) {
      AppLogger.debug('[Kugou] Error parsing KRC: $error');
      return [];
    }
  }

  static List<Lyric> _parseText(String content) {
    final lines = <Lyric>[];
    final unescape = HtmlUnescape();
    final linePattern = RegExp(r'^\[(\d+),(\d+)\](.*)$');
    final wordPattern = RegExp(r'<(\d+),(\d+),\d+>([^<]*)');

    for (final rawLine in content.split(RegExp(r'\r?\n'))) {
      final lineMatch = linePattern.firstMatch(rawLine.trimRight());
      if (lineMatch == null) continue;

      final start = int.parse(lineMatch.group(1)!);
      final duration = int.parse(lineMatch.group(2)!);
      final body = lineMatch.group(3)!;
      final parts = <LyricInlinePart>[];
      final text = StringBuffer();

      for (final match in wordPattern.allMatches(body)) {
        final offset = int.parse(match.group(1)!);
        final wordDuration = int.parse(match.group(2)!);
        final word = unescape.convert(match.group(3)!);
        text.write(word);
        parts.add(
          LyricInlinePart(
            startTime: Duration(milliseconds: start + offset),
            endTime: Duration(milliseconds: start + offset + wordDuration),
            text: word,
          ),
        );
      }

      final lineText = parts.isEmpty ? unescape.convert(body) : text.toString();
      if (lineText.trim().isEmpty) continue;
      lines.add(
        Lyric(
          startTime: Duration(milliseconds: start),
          endTime: Duration(milliseconds: start + duration),
          text: lineText,
          inlineParts: parts.isEmpty ? null : parts,
        ),
      );
    }

    lines.sort((a, b) => a.startTime.compareTo(b.startTime));
    return lines;
  }
}
