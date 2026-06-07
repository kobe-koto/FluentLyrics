import 'dart:convert';
import '../models/lyric_model.dart';
import 'app_logger.dart';

class MusixmatchRichParser {
  static List<Lyric> parse(String jsonString) {
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((line) {
        final double ts = (line['ts'] as num).toDouble();
        final double te = (line['te'] as num).toDouble();
        final String text = line['x'] ?? '';
        final List<dynamic>? parts = line['l'];

        List<LyricInlinePart>? inlineParts;
        if (parts != null) {
          inlineParts = [];
          for (int i = 0; i < parts.length; i++) {
            final part = parts[i];
            final String charText = part['c'] ?? '';
            final double offset = (part['o'] as num).toDouble();

            final startTime = Duration(
              milliseconds: ((ts + offset) * 1000).toInt(),
            );

            // Estimate end time based on next part's offset or line end time
            double nextOffset;
            if (i < parts.length - 1) {
              nextOffset = (parts[i + 1]['o'] as num).toDouble();
            } else {
              nextOffset = te - ts;
            }

            final endTime = Duration(
              milliseconds: ((ts + nextOffset) * 1000).toInt(),
            );

            inlineParts.add(
              LyricInlinePart(
                startTime: startTime,
                endTime: endTime,
                text: charText,
              ),
            );
          }
        }

        return Lyric(
          startTime: Duration(milliseconds: (ts * 1000).toInt()),
          endTime: Duration(milliseconds: (te * 1000).toInt()),
          text: text,
          inlineParts: inlineParts,
        );
      }).toList();
    } catch (e) {
      AppLogger.debug('Error parsing Musixmatch rich sync: $e');
      return [];
    }
  }
}

class EnhancedLrcParser {
  static List<Lyric> parse(String content) {
    final List<Lyric> lyrics = [];
    final lineRegex = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');
    final wordRegex = RegExp(r'<(\d+):(\d+\.\d+)>(.[^<]*)');

    final lines = content.split('\n');
    for (var lineStr in lines) {
      final lineMatch = lineRegex.firstMatch(lineStr);
      if (lineMatch != null) {
        final minutes = int.parse(lineMatch.group(1)!);
        final seconds = double.parse(lineMatch.group(2)!);
        final String wordsContent = lineMatch.group(3)!;

        final startTime = Duration(
          minutes: minutes,
          milliseconds: (seconds * 1000).toInt(),
        );

        final List<LyricInlinePart> inlineParts = [];
        final Iterable<Match> wordMatches = wordRegex.allMatches(wordsContent);

        String fullText = '';
        List<Match> matches = wordMatches.toList();
        for (int i = 0; i < matches.length; i++) {
          final match = matches[i];
          final wMin = int.parse(match.group(1)!);
          final wSec = double.parse(match.group(2)!);
          final String wordText = match.group(3)!;

          final wStart = Duration(
            minutes: wMin,
            milliseconds: (wSec * 1000).toInt(),
          );
          fullText += wordText;

          Duration wEnd;
          if (i < matches.length - 1) {
            final nextMatch = matches[i + 1];
            final nMin = int.parse(nextMatch.group(1)!);
            final nSec = double.parse(nextMatch.group(2)!);
            wEnd = Duration(minutes: nMin, milliseconds: (nSec * 1000).toInt());
          } else {
            // We'll fix line end time later and then update this
            wEnd = wStart + const Duration(milliseconds: 500);
          }

          inlineParts.add(
            LyricInlinePart(startTime: wStart, endTime: wEnd, text: wordText),
          );
        }

        lyrics.add(
          Lyric(
            startTime: startTime,
            text: fullText.isEmpty ? wordsContent.trim() : fullText,
            inlineParts: inlineParts.isNotEmpty ? inlineParts : null,
          ),
        );
      }
    }

    // Sort and calculate end times
    lyrics.sort((a, b) => a.startTime.compareTo(b.startTime));
    for (int i = 0; i < lyrics.length; i++) {
      Duration? lineEnd;
      if (i < lyrics.length - 1) {
        lineEnd = lyrics[i + 1].startTime;
      }

      if (lineEnd != null) {
        final current = lyrics[i];
        lyrics[i] = Lyric(
          startTime: current.startTime,
          endTime: lineEnd,
          text: current.text,
          inlineParts: current.inlineParts,
        );

        // Update the last word's end time to the line's end time if it exceeds it or is the placeholder
        if (current.inlineParts != null && current.inlineParts!.isNotEmpty) {
          final lastPart = current.inlineParts!.last;
          if (lastPart.endTime < lastPart.startTime ||
              lastPart.endTime ==
                  lastPart.startTime + const Duration(milliseconds: 500)) {
            // update last part end time
            final newParts = List<LyricInlinePart>.from(current.inlineParts!);
            newParts[newParts.length - 1] = LyricInlinePart(
              startTime: lastPart.startTime,
              endTime: lineEnd,
              text: lastPart.text,
            );
            lyrics[i] = Lyric(
              startTime: current.startTime,
              endTime: lineEnd,
              text: current.text,
              inlineParts: newParts,
            );
          }
        }
      }
    }

    return lyrics;
  }
}

class QQRichParser {
  // Strict timestamp pattern: '(offsetMs,durationMs)'.  We anchor on these
  // and treat everything else (including any literal '(' in the lyric text)
  // as plain text content.  This is the inverse of the previous approach,
  // which used `([^\(]+)` and broke on lines like
  //   `[3773,19]Mastered (3773,3)by：권남우 ((3776,3)Asst. (3779,3)유은진)`
  // — a literal '(' in the lyric text would shift the part boundary and
  // silently drop characters.
  static final RegExp _lineRegex = RegExp(r'^\[(\d+),(\d+)\](.*)$');
  static final RegExp _timestampRegex = RegExp(r'\((\d+),(\d+)\)');

  static List<Lyric> parse(String content) {
    try {
      final lyrics = <Lyric>[];

      for (final rawLine in content.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty) {
          continue;
        }

        final lineMatch = _lineRegex.firstMatch(line);
        if (lineMatch == null) {
          continue;
        }

        final lineStartMs = int.parse(lineMatch.group(1)!);
        final lineDurationMs = int.parse(lineMatch.group(2)!);
        final lineContent = lineMatch.group(3) ?? '';

        final parsed = _parseLineContent(lineContent, lineStartMs);
        final inlineParts = parsed.inlineParts;
        final plainText = parsed.plainText;

        final text = inlineParts.isNotEmpty ? plainText : lineContent.trim();
        lyrics.add(
          Lyric(
            startTime: Duration(milliseconds: lineStartMs),
            endTime: Duration(milliseconds: lineStartMs + lineDurationMs),
            text: text,
            inlineParts: inlineParts.isNotEmpty ? inlineParts : null,
          ),
        );
      }

      return lyrics;
    } catch (e) {
      AppLogger.debug('Error parsing QQ rich sync: $e');
      return [];
    }
  }

  /// Split [lineContent] into `(text, (offset, duration))` parts by treating
  /// every `(\d+,\d+)` group as a strict timestamp anchor.  The text owned by
  /// a timestamp is everything from the end of the previous timestamp (or the
  /// start of the line) up to the timestamp itself — literal parentheses in
  /// that range are preserved verbatim.
  ///
  /// Edge cases:
  /// - Text *before* the first timestamp is prepended to the first part's
  ///   text.
  /// - Text *after* the last timestamp (e.g. a trailing word without its own
  ///   timing) is appended to the last part's text.
  /// - A part whose text range is empty after stripping the timestamp itself
  ///   is still kept so that downstream highlighting renders its glyphs (none
  ///   in this case, but it keeps timing slot count == timestamp count).
  static _ParsedLineContent _parseLineContent(
    String lineContent,
    int lineStartMs,
  ) {
    final matches = _timestampRegex.allMatches(lineContent).toList();
    if (matches.isEmpty) {
      return const _ParsedLineContent(inlineParts: [], plainText: '');
    }

    final inlineParts = <LyricInlinePart>[];
    final plainText = StringBuffer();

    int cursor = 0;
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final partText = lineContent.substring(cursor, match.start);
      final partAbsMs = int.parse(match.group(1)!);
      final partDurationMs = int.parse(match.group(2)!);

      plainText.write(partText);
      inlineParts.add(
        LyricInlinePart(
          startTime: Duration(milliseconds: partAbsMs),
          endTime: Duration(milliseconds: partAbsMs + partDurationMs),
          text: partText,
        ),
      );
      cursor = match.end;
    }

    // Trailing text after the final timestamp — typically a tail like "Sound"
    // in QQ's annotation lines.  Glue it to the last part so it isn't lost.
    if (cursor < lineContent.length && inlineParts.isNotEmpty) {
      final tail = lineContent.substring(cursor);
      if (tail.isNotEmpty) {
        final last = inlineParts.removeLast();
        final mergedText = last.text + tail;
        plainText.write(tail);
        inlineParts.add(
          LyricInlinePart(
            startTime: last.startTime,
            endTime: last.endTime,
            text: mergedText,
          ),
        );
      }
    }

    // Use lineStartMs purely as a sanity reference; the parts already carry
    // absolute timings from the timestamp's `o` field.
    if (lineStartMs < 0) {
      AppLogger.debug('QQRichParser: negative lineStartMs $lineStartMs');
    }

    return _ParsedLineContent(
      inlineParts: inlineParts,
      plainText: plainText.toString(),
    );
  }
}

class _ParsedLineContent {
  final List<LyricInlinePart> inlineParts;
  final String plainText;

  const _ParsedLineContent({
    required this.inlineParts,
    required this.plainText,
  });
}
