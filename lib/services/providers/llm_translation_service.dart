import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../models/lyric_model.dart';
import '../../models/general_translation_request_data.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/app_logger.dart';
import '../settings_service.dart';

class LlmTranslationService {
  bool checkTranslationSupport(String language) {
    if (language.startsWith('llm:')) {
      return true;
    }
    return false;
  }

  final SettingsService _settingsService;

  LlmTranslationService(this._settingsService);

  Future<LyricsResult> fetchTranslation(
    GeneralTranslationRequestData data,
    String targetLanguage,
  ) async {
    try {
      final baseURI = (await _settingsService.getLlmApiEndpoint()).current;
      final baseURIParsed = Uri.parse(baseURI);
      final apiKey = (await _settingsService.getLlmApiKey()).current;
      final model = (await _settingsService.getLlmModel()).current;

      if (baseURI.isEmpty || apiKey.isEmpty) {
        AppLogger.debug('[LLM Translation] Endpoint or API Key is empty.');
        return LyricsResult.empty();
      }
      // check for dummy endpoint
      if (baseURIParsed.host.contains('dummy.endpoint.example')) {
        AppLogger.debug('[LLM Translation] Endpoint is dummy, skipping.');
        return LyricsResult.empty();
      }

      final llmReasoningEffort =
          (await _settingsService.getLlmReasoningEffort()).current;

      // Parse original content to get non-empty lines
      final contentfulOriginalLyrics = LrcParser.parse(
        data.content,
      ).lyrics.where((e) => e.text.trim().isNotEmpty).toList();

      if (contentfulOriginalLyrics.isEmpty) {
        return LyricsResult.empty();
      }

      // convert to "line_n: <text>"
      final Map<String, String> linesToTranslate = {};
      for (var i = 0; i < contentfulOriginalLyrics.length; i++) {
        final lineKey = 'line_${i + 1}';
        linesToTranslate[lineKey] = contentfulOriginalLyrics[i].text;
      }

      // Call LLM API
      final int start = FlutterTimeline.now;

      final Map<String, dynamic> requestBody = {
        'model': model.isNotEmpty ? model : 'openai/gpt-oss-120b',
        'messages': [
          {
            'role': 'system',
            'content': '''
You are a professional translator specialized in song lyrics.

Requirements:
1. The output MUST follows the structure defined below.
2. Preserve the poetic style, emotional tone, and rhythm.
3. If a line is empty or instrumental, return an empty string.
4. You MUST NOT use Markdown formatting (no codeblock like \\`\\`\\`json). Output raw JSON only.
5. You MUST NOT add comments or notes.

Instructions:
1. Detect the source language of the lyrics.
2. If translation is not needed (eg. the source language is the same as the target language), 
   you MUST ONLY return "SKIP".
3. If the source language is different from the target language, 
   translate the lyrics to the target language following the structure.

Structure:
Input Contains:
  "line_<N>": "<Original Lyrics Text>",
  ...more lines...
Output:
  - Translation (MUST be a valid JSON):
    {
      "translation": {
        "line_<N>": "<Translated Lyrics Text>",
        ...more lines...
      },
      "metadata": {
        "source_language": "<Source Language>",
        "target_language": "<Target Language>"
      }
    }
  - Skip Translation (MUST ONLY return "SKIP"):
    SKIP
''',
          },
          {
            'role': 'user',
            'content':
                '''
Song Metadata:
Title: ${data.title}
Artist: ${data.artist}

Target Language: ${targetLanguage.substring(4).trim()}
Original Lyrics: 
${linesToTranslate.entries.map((e) => '${e.key}: ${e.value}').join('\n')}
''',
          },
        ],
        'temperature': 0.75,
        'stream': false,
        'max_tokens': 16384,
      };

      if (llmReasoningEffort == 'none') {
        requestBody['thinking'] = {'type': 'disabled'};
      } else if (llmReasoningEffort != 'auto') {
        requestBody['reasoning_effort'] = llmReasoningEffort;
      }

      final requestURL = baseURIParsed.replace(
        pathSegments: [...baseURIParsed.pathSegments, 'chat', 'completions'],
      );

      final response = await http.post(
        requestURL,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );
      final int end = FlutterTimeline.now;
      final int requestElapsed = (end - start) ~/ 1000;
      AppLogger.debug('[LLM Translation] Request Elapsed: $requestElapsed ms');

      if (response.statusCode != 200) {
        AppLogger.debug(
          '[LLM Translation] Failed: ${response.statusCode} ${response.body}',
        );
        return LyricsResult.empty();
      }

      var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      String? content = jsonResponse['choices']?[0]?['message']?['content']
          ?.trim();

      // try strip out <thought></thought> block
      if (content != null) {
        final thoughtPattern = RegExp(
          r'<thought>.*?</thought>(.*)',
          multiLine: true,
          dotAll: true,
        );
        final match = thoughtPattern.firstMatch(content);
        if (match != null) {
          content = match.group(1);
        }
      }

      content = content?.trim();

      if (content == null || content.isEmpty) {
        return LyricsResult.empty();
      }

      // Handle SKIP response (case-insensitive and trimmed)
      if (content.toUpperCase() == 'SKIP') {
        return LyricsResult(
          lyrics: contentfulOriginalLyrics,
          source: 'SKIPPED',
          translation: false,
          translationInvalidatable: true,
        );
      }
      dynamic translatedLines;
      // try to decode raw as json directly
      try {
        jsonResponse = jsonDecode(content);
        translatedLines = jsonResponse['translation'];
      } catch (e) {
        AppLogger.debug(
          '[LLM Translation] Fail to parse response as raw JSON, trying to strip...',
        );
        try {
          // check if markdown codeblock present
          final codeblockPattern = RegExp(
            r'\`\`\`(?:.*)\n([\s\S]*?)\n\s*\`\`\`',
          );

          final match = codeblockPattern.allMatches(content);
          if (match.isNotEmpty) {
            // try every group until we found a valid response
            for (var m in match) {
              final codeblockContent = m.group(1);
              if (codeblockContent != null) {
                try {
                  jsonResponse = jsonDecode(codeblockContent);
                  translatedLines = jsonResponse['translation'];
                  if (translatedLines != null) {
                    break;
                  }
                } catch (e) {
                  continue;
                }
              }
            }
          }
        } catch (e) {
          AppLogger.debug(
            '[LLM Translation] Error: Model produced malformed JSON. Expected List or "SKIP", got $translatedLines',
          );
        }
      }

      // Handle SKIP response (case-insensitive and trimmed)
      if ((translatedLines is String &&
              translatedLines.toUpperCase() == 'SKIP') ||
          (translatedLines is Map<String, dynamic> &&
              translatedLines.values.first.toString().toUpperCase() ==
                  'SKIP')) {
        return LyricsResult(
          lyrics: contentfulOriginalLyrics,
          source: 'SKIPPED',
          translation: false,
          translationInvalidatable: true,
        );
      }

      if (translatedLines is! Map<String, dynamic>) {
        AppLogger.debug(
          '[LLM Translation] Error: Model produced malformed JSON. Expected Map<String, dynamic> or "SKIP", got $translatedLines',
        );
        return LyricsResult.empty();
      }

      final List<Map<String, String>> rawTranslation = [];
      for (var item in translatedLines.entries) {
        final originalLine = linesToTranslate[item.key];
        if (originalLine == null) {
          continue; // pair fail?
        }
        rawTranslation.add({
          'original': originalLine,
          'translated': item.value,
        });
      }

      return LyricsResult(
        lyrics: [],
        rawTranslation: rawTranslation,
        source: 'LLM Translation',
        language: targetLanguage,
        translation: true,
        translationInvalidatable: true,
        translationProvider: 'LLM Translation',
        translationContributor:
            'Model $model, Request Elapsed ${requestElapsed / 1000}s',
      );
    } catch (e) {
      AppLogger.debug('[LLM Translation] Error: $e');
      return LyricsResult.empty();
    }
  }
}
