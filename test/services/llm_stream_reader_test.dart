import 'dart:async';
import 'dart:convert';

import 'package:fluent_lyrics/services/providers/llm_stream_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('estimateTokenCount counts CJK and short ASCII deltas', () {
    expect(estimateTokenCount(''), 0);
    expect(estimateTokenCount('Hi'), 1);
    expect(estimateTokenCount('歌词'), 2);
  });

  test('parseLlmDelta keeps reasoning in the pace text only', () {
    final delta = parseLlmDelta(
      '{"choices":[{"delta":{"reasoning_content":"think","content":"歌"}}]}',
    );

    expect(delta?.content, '歌');
    expect(delta?.paceText, 'think歌');
  });

  test('collectLlmOutput aborts when the first token never arrives', () async {
    final stream = StreamController<List<int>>();
    final future = collectLlmOutput(
      stream.stream,
      eventStream: true,
      timeToFirstToken: const Duration(milliseconds: 20),
      minTokensPerSecond: 0,
    );

    await expectLater(future, throwsA(isA<LlmPaceException>()));
    await stream.close();
  });

  test('collectLlmOutput assembles streamed content', () async {
    final payload = [
      'data: {"choices":[{"delta":{"content":"{\\"translation\\":"}}]}\n',
      'data: {"choices":[{"delta":{"content":"{\\"line_1\\":\\"hi\\"}"}}]}\n',
      'data: [DONE]\n',
    ].join();
    final text = await collectLlmOutput(
      Stream<List<int>>.value(utf8.encode(payload)),
      eventStream: true,
      timeToFirstToken: const Duration(seconds: 2),
      minTokensPerSecond: 0,
    );

    expect(text, contains('line_1'));
  });
}
