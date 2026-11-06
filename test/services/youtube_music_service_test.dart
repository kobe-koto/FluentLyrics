import 'dart:convert';

import 'package:fluent_lyrics/services/lyrics_request_scope.dart';
import 'package:fluent_lyrics/services/providers/youtube_music_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('fetches fully timed lyrics through search, next and browse', () async {
    final client = _YoutubeClient();
    final result = await YoutubeMusicService().fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      durationSeconds: 180,
      scope: LyricsRequestScope(client: client),
    );

    expect(result.source, 'YouTube Music');
    expect(result.isSynced, isTrue);
    expect(result.lyrics.map((line) => line.text), ['hello', 'world']);
    expect(result.lyrics[0].startTime.inMilliseconds, 1000);
    expect(result.lyrics[0].endTime!.inMilliseconds, 2000);
    expect(client.paths, [
      '/youtubei/v1/search',
      '/youtubei/v1/next',
      '/youtubei/v1/browse',
    ]);
  });

  test('falls back to plain lines when one cue is missing', () async {
    final result = await YoutubeMusicService().fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      durationSeconds: 180,
      scope: LyricsRequestScope(client: _YoutubeClient(missingCue: true)),
    );

    expect(result.isSynced, isFalse);
    expect(
      result.lyrics.every((line) => line.startTime == Duration.zero),
      isTrue,
    );
  });

  test('converts music note markers into timed blank interludes', () async {
    final result = await YoutubeMusicService().fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      durationSeconds: 180,
      scope: LyricsRequestScope(client: _YoutubeClient(interlude: true)),
    );

    expect(result.isSynced, isTrue);
    expect(result.lyrics[1].text, isEmpty);
    expect(result.lyrics[1].startTime.inMilliseconds, 2000);
    expect(result.lyrics[1].endTime!.inMilliseconds, 3000);
  });
}

class _YoutubeClient extends http.BaseClient {
  _YoutubeClient({this.missingCue = false, this.interlude = false});

  final bool missingCue;
  final bool interlude;
  final paths = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    paths.add(request.url.path);
    final body = switch (request.url.path) {
      '/youtubei/v1/search' => {
        'contents': {
          'tabbedSearchResultsRenderer': {
            'tabs': {
              'tabRenderer': {
                'content': {
                  'sectionListRenderer': {
                    'contents': {
                      'musicShelfRenderer': {
                        'contents': {
                          'musicResponsiveListItemRenderer': {
                            'playlistItemData': {'videoId': 'video'},
                            'flexColumns': {
                              'musicResponsiveListItemFlexColumnRenderer': [
                                {
                                  'text': {
                                    'runs': {'text': 'Song'},
                                  },
                                },
                                {
                                  'text': {
                                    'runs': [
                                      {'text': 'Artist'},
                                      {'text': ' • '},
                                      {'text': '3:00'},
                                    ],
                                  },
                                },
                              ],
                            },
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
      '/youtubei/v1/next' => {
        'contents': {
          'singleColumnMusicWatchNextResultsRenderer': {
            'tabbedRenderer': {
              'watchNextTabbedResultsRenderer': {
                'tabs': {
                  'tabRenderer': {
                    'unselectable': false,
                    'endpoint': {
                      'browseEndpoint': {
                        'browseId': 'lyrics',
                        'browseEndpointContextSupportedConfigs': {
                          'browseEndpointContextMusicConfig': {
                            'pageType': 'MUSIC_PAGE_TYPE_TRACK_LYRICS',
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
      _ => {
        'contents': {
          'elementRenderer': {
            'newElement': {
              'type': {
                'componentType': {
                  'model': {
                    'timedLyricsModel': {
                      'lyricsData': {
                        'timedLyricsData': [
                          {
                            'lyricLine': 'hello',
                            'cueRange': {
                              'startTimeMilliseconds': '1000',
                              'endTimeMilliseconds': '2000',
                            },
                          },
                          {
                            'lyricLine': interlude ? '♪' : 'world',
                            if (!missingCue)
                              'cueRange': {
                                'startTimeMilliseconds': '2000',
                                'endTimeMilliseconds': '3000',
                              },
                          },
                        ],
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    };
    final encoded = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(
      Stream.value(encoded),
      200,
      request: request,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
