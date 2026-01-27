import '../models/lyric_model.dart';

/// Result of parsing LRC content with optional metadata trimming.
class LrcParseResult {
  /// The parsed lyric lines.
  final List<Lyric> lyrics;

  /// Metadata lines that were trimmed, as key-value pairs.
  /// Key: position (e.g., "作词", "作曲"), Value: staff names
  /// Empty if trimMetadata was false or no metadata was found.
  final Map<String, String> trimmedMetadata;

  LrcParseResult({required this.lyrics, this.trimmedMetadata = const {}});
}

class LrcParser {
  static LrcParseResult parse(String lrcContent, {bool trimMetadata = false}) {
    final List<Lyric> lyrics = [];
    final RegExp regExp = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');

    for (final line in lrcContent.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();

        final duration = Duration(
          minutes: minutes,
          milliseconds: (seconds * 1000).toInt(),
        );

        lyrics.add(Lyric(startTime: duration, text: text));
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

    if (trimMetadata) {
      return trimMetadataLines(lyricsWithEndTime);
    }

    return LrcParseResult(lyrics: lyricsWithEndTime);
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
  static LrcParseResult trimMetadataLines(List<Lyric> lyrics) {
    if (lyrics.isEmpty) return LrcParseResult(lyrics: lyrics);

    final List<Lyric> result = List<Lyric>.from(lyrics);
    final Map<String, String> trimmedMetadata = {};

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
        break;
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
        break;
      }
    }

    return LrcParseResult(lyrics: result, trimmedMetadata: trimmedMetadata);
  }
}
