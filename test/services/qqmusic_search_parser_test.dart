import 'package:fluent_lyrics/services/providers/qqmusic_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads songs from the module-keyed search response', () {
    final songs = QQMusicSearchParser.songList({
      'code': 0,
      'music.search.SearchCgiService': {
        'code': 0,
        'data': {
          'code': 0,
          'body': {
            'song': {
              'list': [
                {
                  'id': 1,
                  'mid': 'mid1',
                  'name': 'Blue Wind',
                  'interval': 180,
                  'singer': [
                    {'name': 'Koto'},
                  ],
                  'album': {'mid': 'album1'},
                },
              ],
            },
          },
        },
      },
    });

    expect(songs, hasLength(1));
    expect(songs.single['name'], 'Blue Wind');
    expect(songs.single['mid'], 'mid1');
    expect(songs.single['interval'], 180);
    expect(songs.single['album']['mid'], 'album1');
  });

  test('returns no songs when the new envelope has an empty list', () {
    expect(
      QQMusicSearchParser.songList({
        'code': 0,
        'music.search.SearchCgiService': {
          'code': 0,
          'data': {
            'body': {
              'song': {'list': []},
            },
          },
        },
      }),
      isEmpty,
    );
  });

  test('surfaces a non-zero module code instead of reading req_1', () {
    expect(
      () => QQMusicSearchParser.songList({
        'code': 0,
        'req_1': {
          'code': 0,
          'data': {
            'body': {
              'song': {
                'list': [
                  {'name': 'ignored'},
                ],
              },
            },
          },
        },
        'music.search.SearchCgiService': {'code': 2001},
      }),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('code 2001'),
        ),
      ),
    );
  });
}
