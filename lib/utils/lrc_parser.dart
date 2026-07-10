import 'dart:math';
import '../models/lyric_model.dart';
import '../../utils/string_similarity.dart';
import 'package:html_unescape/html_unescape.dart';
import 'app_logger.dart';

/// Result of parsing LRC content with optional metadata trimming.
class LrcParseResult {
  /// The parsed lyric lines.
  final List<Lyric> lyrics;

  /// Metadata lines that were trimmed, as key-value pairs.
  /// Key: position (e.g., "作词", "作曲"), Value: staff names
  /// Empty if trimMetadata was false or no metadata was found.
  final Map<String, String> trimmedMetadata;
  final Map<String, String> lrcMetadata;

  LrcParseResult({
    required this.lyrics,
    this.trimmedMetadata = const {},
    this.lrcMetadata = const {},
  });
}

class LrcParser {
  static LrcParseResult parse(String lrcContent, {bool trimMetadata = false}) {
    final List<Lyric> lyrics = [];
    final RegExp timeTagExp = RegExp(r'\[(\d+):(\d+\.\d+)\]');

    final Map<String, String> lrcMetadata = {};

    for (final line in lrcContent.split('\n')) {
      final timeMatches = timeTagExp.allMatches(line).toList();
      final tagMatch = RegExp(r'\[([a-zA-Z]+):(.*)\]').firstMatch(line);

      if (timeMatches.isNotEmpty) {
        // Extract text after the last timestamp tag
        final text = line.substring(timeMatches.last.end).trim();

        // Create a Lyric entry for each stacked timestamp
        for (final match in timeMatches) {
          final minutes = int.parse(match.group(1)!);
          final seconds = double.parse(match.group(2)!);

          final duration = Duration(
            minutes: minutes,
            milliseconds: (seconds * 1000).toInt(),
          );

          lyrics.add(Lyric(startTime: duration, text: text));
        }
      } else if (tagMatch != null) {
        final key = tagMatch.group(1)!.trim();
        final value = tagMatch.group(2)!.trim();
        lrcMetadata[key] = value;
      } else if (line.trim().isNotEmpty && !line.startsWith('[')) {
        // Plain text lines without timestamps (rare in LRC but possible)
        lyrics.add(Lyric(startTime: Duration.zero, text: line.trim()));
      }
    }

    lyrics.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Calculate end times
    final List<Lyric> lyricsWithEndTime = [];
    for (int i = 0; i < lyrics.length; i++) {
      final current = lyrics[i];
      Duration? endTime;
      if (i < lyrics.length - 1) {
        endTime = lyrics[i + 1].startTime;
      }
      lyricsWithEndTime.add(
        Lyric(
          startTime: current.startTime,
          endTime: endTime,
          text: current.text,
          inlineParts: current.inlineParts,
        ),
      );
    }

    List<Lyric> lyricsResult = lyricsWithEndTime;

    // escape all lyric text
    var unescape = HtmlUnescape();
    List<Lyric> lyricsResultEscaped = [];
    for (var lyric in lyricsResult) {
      // escape all inline parts (if any)
      List<LyricInlinePart> inlinePartsEscaped = [];
      if (lyric.inlineParts != null) {
        for (var part in lyric.inlineParts!) {
          inlinePartsEscaped.add(
            LyricInlinePart(
              startTime: part.startTime,
              endTime: part.endTime,
              text: unescape.convert(part.text),
            ),
          );
        }
      }
      lyricsResultEscaped.add(
        Lyric(
          startTime: lyric.startTime,
          endTime: lyric.endTime,
          text: unescape.convert(lyric.text),
          inlineParts: inlinePartsEscaped,
        ),
      );
    }
    lyricsResult = lyricsResultEscaped;

    // trim metadata lines
    Map<String, String> trimmedMetadataResult = {};
    if (trimMetadata) {
      final trimmedResult = trimMetadataLines(
        lyricsWithEndTime,
        lrcMetadata: lrcMetadata,
      );
      lyricsResult = trimmedResult.lyrics;
      trimmedMetadataResult = trimmedResult.trimmedMetadata;
    }

    lyricsResult = trimEmptyLines(lyricsResult);

    return LrcParseResult(
      lyrics: lyricsResult,
      trimmedMetadata: trimmedMetadataResult,
      lrcMetadata: lrcMetadata,
    );
  }

  /// Trims empty lines from lyrics (head and tail).
  static List<Lyric> trimEmptyLines(List<Lyric> lyrics) {
    if (lyrics.isEmpty) return lyrics;

    final List<Lyric> result = List<Lyric>.from(lyrics);

    // trim empty lines from head
    while (result.isNotEmpty && result.first.text.trim().isEmpty) {
      result.removeAt(0);
    }

    // trim empty lines from tail
    while (result.isNotEmpty && result.last.text.trim().isEmpty) {
      result.removeLast();
    }

    return result;
  }

  /// Trims metadata lines from lyrics (head and tail).
  /// Metadata lines have format: [mm:ss.xx]position:staff names
  /// where position is like "作词" (songwriter), "作曲" (composer), etc.
  /// and the full-width colon "：" is used instead of regular ":"
  /// This pattern matches metadata commonly found in Chinese lyrics.
  ///
  /// Returns a LrcParseResult with:
  /// - lyrics: the trimmed lyric lines
  /// - trimmedMetadata: map of removed metadata with position as key and staff names as value
  static LrcParseResult trimMetadataLines(
    List<Lyric> lyrics, {
    Map<String, String> lrcMetadata = const {},
  }) {
    if (lyrics.isEmpty) return LrcParseResult(lyrics: lyrics);

    final List<Lyric> result = List<Lyric>.from(lyrics);
    final Map<String, String> trimmedMetadata = {};

    String? title = lrcMetadata['title'] ?? lrcMetadata['ti'];
    String? artist = lrcMetadata['artist'] ?? lrcMetadata['ar'];

    // Pattern for metadata: text contains full-width colon ： followed by names
    // Common metadata positions: 作词, 作曲, 编曲, 制作, 混音, 母带
    final metadataPattern = RegExp(r'(.*?[\u0020\u3000]*)(：|:)(.*)');

    // Trim from head
    while (result.isNotEmpty) {
      final text = result.first.text.trim();
      final match = metadataPattern.firstMatch(text);
      if (text.isNotEmpty && match != null) {
        final position = match.group(1)?.trim() ?? '';
        final staff = match.group(3)?.trim() ?? '';
        if (position.isNotEmpty) {
          trimmedMetadata[position] = staff;
        }
        result.removeAt(0);
      } else if (text.isEmpty) {
        result.removeAt(0);
      } else {
        if (title != null &&
            artist != null &&
            _isTitleAndArtistLine(title, artist, text) >= 0.6) {
          result.removeAt(0);
        } else {
          break;
        }
      }
    }

    // Trim from tail
    while (result.isNotEmpty) {
      final text = result.last.text.trim();
      final match = metadataPattern.firstMatch(text);
      if (text.isNotEmpty && match != null) {
        final position = match.group(1)?.trim() ?? '';
        final staff = match.group(3)?.trim() ?? '';
        if (position.isNotEmpty) {
          trimmedMetadata[position] = staff;
        }
        result.removeLast();
      } else if (text.isEmpty) {
        result.removeLast();
      } else {
        if (title != null &&
            artist != null &&
            _isTitleAndArtistLine(title, artist, text) >= 0.6) {
          result.removeLast();
        } else {
          break;
        }
      }
    }

    return LrcParseResult(lyrics: result, trimmedMetadata: trimmedMetadata);
  }

  static double _isTitleAndArtistLine(
    String title,
    String artist,
    String line,
  ) {
    String trimTitleKeyword_1 = '$title - $artist';
    String trimTitleKeyword_2 = '$artist - $title';
    // check the similarity of the first line with the title keyword
    final similarity_1 = JaroWinklerSimilarity.getJaroWinklerScore(
      line,
      trimTitleKeyword_1,
    );
    final similarity_2 = JaroWinklerSimilarity.getJaroWinklerScore(
      line,
      trimTitleKeyword_2,
    );
    AppLogger.debug(
      '[trimMetadataLines] similarity for first line "$line" with keyword "$trimTitleKeyword_1": $similarity_1',
    );
    AppLogger.debug(
      '[trimMetadataLines] similarity for first line "$line" with keyword "$trimTitleKeyword_2": $similarity_2',
    );
    return max(similarity_1, similarity_2);
  }
}
