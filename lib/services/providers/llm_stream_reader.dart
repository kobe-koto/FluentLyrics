import 'dart:async';
import 'dart:convert';

class LlmPaceException implements Exception {
  LlmPaceException(this.message, {required this.beforeFirstToken});

  final String message;
  final bool beforeFirstToken;

  @override
  String toString() => message;
}

class LlmDelta {
  const LlmDelta({this.content = '', this.paceText = ''});

  final String content;
  final String paceText;

  bool get isEmpty => content.isEmpty && paceText.isEmpty;
}

/// Rough token estimate. CJK characters count as one token; other runs use
/// about four characters per token. Streaming deltas are often one token, so
/// a short ASCII delta still counts as one.
int estimateTokenCount(String text) {
  if (text.isEmpty) return 0;
  var tokens = 0;
  var asciiRun = 0;

  void flushAscii() {
    if (asciiRun == 0) return;
    tokens += (asciiRun / 4).ceil();
    asciiRun = 0;
  }

  for (final rune in text.runes) {
    if (_isCjk(rune)) {
      flushAscii();
      tokens += 1;
    } else if (rune <= 32) {
      flushAscii();
    } else {
      asciiRun += 1;
    }
  }
  flushAscii();
  return tokens;
}

bool _isCjk(int rune) {
  return (rune >= 0x2E80 && rune <= 0x9FFF) ||
      (rune >= 0xF900 && rune <= 0xFAFF) ||
      (rune >= 0xAC00 && rune <= 0xD7AF) ||
      (rune >= 0x3040 && rune <= 0x30FF);
}

/// Tracks time-to-first-token and a minimum token rate.
///
/// A rate of `0` or a null [timeToFirstToken] disables that limit. After the
/// first token, the rate is enforced as a maximum silence of
/// `max(1s, 1 / minTokensPerSecond)`, so a bursty stream is not aborted on a
/// single sub-second gap.
class LlmStreamPacer {
  LlmStreamPacer({
    required this.timeToFirstToken,
    required this.minTokensPerSecond,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration? timeToFirstToken;
  final double minTokensPerSecond;
  final DateTime Function() _clock;

  DateTime? _started;
  DateTime? _lastToken;

  bool get sawToken => _lastToken != null;

  void start() {
    _started ??= _clock();
  }

  Duration? deadlineFrom(DateTime now) {
    _started ??= now;
    if (_lastToken == null) {
      final limit = timeToFirstToken;
      if (limit == null || limit <= Duration.zero) return null;
      final remaining = limit - now.difference(_started!);
      return remaining.isNegative ? Duration.zero : remaining;
    }
    if (minTokensPerSecond <= 0) return null;
    final stallMs = (1000 / minTokensPerSecond).ceil().clamp(1000, 3600000);
    final remaining =
        Duration(milliseconds: stallMs) - now.difference(_lastToken!);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void onText(String text) {
    if (estimateTokenCount(text) <= 0) return;
    _lastToken = _clock();
  }

  LlmPaceException timeoutException() {
    if (!sawToken) {
      final seconds = timeToFirstToken?.inSeconds ?? 0;
      return LlmPaceException(
        'No token within ${seconds}s',
        beforeFirstToken: true,
      );
    }
    return LlmPaceException(
      'Stream fell below $minTokensPerSecond tokens/sec',
      beforeFirstToken: false,
    );
  }
}

LlmDelta? parseLlmDelta(String data) {
  final trimmed = data.trim();
  if (trimmed.isEmpty || trimmed == '[DONE]') return null;
  final decoded = jsonDecode(trimmed);
  if (decoded is! Map) return null;
  final choices = decoded['choices'];
  if (choices is! List || choices.isEmpty || choices.first is! Map) {
    return null;
  }
  final first = choices.first as Map;
  final delta = first['delta'];
  if (delta is Map) {
    final content = delta['content']?.toString() ?? '';
    final reasoning =
        (delta['reasoning_content'] ?? delta['reasoning'])?.toString() ?? '';
    return LlmDelta(content: content, paceText: '$reasoning$content');
  }
  final message = first['message'];
  if (message is Map) {
    final content = message['content']?.toString() ?? '';
    return LlmDelta(content: content, paceText: content);
  }
  return null;
}

class _SseDrain {
  const _SseDrain(this.events, this.rest);

  final List<String> events;
  final String rest;
}

_SseDrain _drainSse(String buffer) {
  final events = <String>[];
  var rest = buffer;
  while (true) {
    final newline = rest.indexOf('\n');
    if (newline < 0) break;
    final line = rest.substring(0, newline).trim();
    rest = rest.substring(newline + 1);
    if (line.startsWith('data:')) {
      events.add(line.substring(5).trim());
    }
  }
  return _SseDrain(events, rest);
}

/// Reads an OpenAI-compatible body, enforcing [timeToFirstToken] and
/// [minTokensPerSecond]. Non-event-stream bodies are treated as one reply:
/// only the first-token deadline applies, because there are no deltas to rate.
Future<String> collectLlmOutput(
  Stream<List<int>> byteStream, {
  required bool eventStream,
  required Duration? timeToFirstToken,
  required double minTokensPerSecond,
}) {
  final pacer = LlmStreamPacer(
    timeToFirstToken: timeToFirstToken,
    minTokensPerSecond: minTokensPerSecond,
  );
  pacer.start();
  final completer = Completer<String>();
  final content = StringBuffer();
  final raw = StringBuffer();
  var sseBuffer = '';
  Timer? timer;
  late StreamSubscription<String> subscription;

  void fail(Object error) {
    if (completer.isCompleted) return;
    timer?.cancel();
    unawaited(subscription.cancel());
    completer.completeError(error);
  }

  void succeed(String value) {
    if (completer.isCompleted) return;
    timer?.cancel();
    unawaited(subscription.cancel());
    completer.complete(value);
  }

  void arm() {
    timer?.cancel();
    final deadline = pacer.deadlineFrom(DateTime.now());
    if (deadline == null) return;
    timer = Timer(deadline, () => fail(pacer.timeoutException()));
  }

  void takeDelta(LlmDelta? delta) {
    if (delta == null || delta.isEmpty) return;
    if (delta.paceText.isNotEmpty) pacer.onText(delta.paceText);
    if (delta.content.isNotEmpty) content.write(delta.content);
    arm();
  }

  arm();
  subscription = utf8.decoder
      .bind(byteStream)
      .listen(
        (text) {
          if (completer.isCompleted) return;
          if (!eventStream) {
            raw.write(text);
            pacer.onText(text);
            arm();
            return;
          }
          sseBuffer += text;
          final drained = _drainSse(sseBuffer);
          sseBuffer = drained.rest;
          for (final event in drained.events) {
            if (event == '[DONE]') {
              succeed(content.toString());
              return;
            }
            try {
              takeDelta(parseLlmDelta(event));
            } on FormatException {
              continue;
            }
          }
        },
        onError: fail,
        onDone: () {
          if (completer.isCompleted) return;
          if (!eventStream) {
            succeed(raw.toString());
            return;
          }
          if (sseBuffer.trim().isNotEmpty) {
            final line = sseBuffer.trim();
            final data = line.startsWith('data:')
                ? line.substring(5).trim()
                : line;
            if (data != '[DONE]') {
              try {
                takeDelta(parseLlmDelta(data));
              } on FormatException {
                // Ignore a trailing partial frame.
              }
            }
          }
          succeed(content.toString());
        },
        cancelOnError: true,
      );
  return completer.future;
}
