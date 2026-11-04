import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rick_morty_flutter_app/data/dio_character_repository.dart';

void main() {
  test('maps API results and the next page without exposing JSON', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://rickandmortyapi.com/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.uri.path, '/api/character');
          expect(options.queryParameters, {'page': 1, 'name': 'Rick'});
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'info': {
                  'next':
                      'https://rickandmortyapi.com/api/character?page=2&name=Rick',
                },
                'results': [
                  {
                    'id': 1,
                    'name': 'Rick Sanchez',
                    'status': 'Alive',
                    'species': 'Human',
                    'origin': {'name': 'Earth'},
                    'location': {'name': 'Citadel'},
                    'image': 'https://example.com/rick.png',
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final page = await DioCharacterRepository(
      dio,
    ).getCharacters(page: 1, name: 'Rick');
    expect(page.nextPage, 2);
    expect(page.characters.single.name, 'Rick Sanchez');
    expect(page.characters.single.origin, 'Earth');
    expect(page.characters.single.location, 'Citadel');
  });

  test('treats a filtered 404 as an empty search result', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://rickandmortyapi.com/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 404),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final repository = DioCharacterRepository(dio);
    final empty = await repository.getCharacters(page: 1, name: 'Nobody');
    expect(empty.characters, isEmpty);
    expect(empty.nextPage, isNull);
    expect(
      repository.getCharacters(page: 1, name: ''),
      throwsA(isA<DioException>()),
    );
  });
}
