import '../models/lyric_model.dart';

class LrcParser {
  static List<Lyric> parse(String lrcContent) {
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
    return lyrics;
  }
}
