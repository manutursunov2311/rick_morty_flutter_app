import 'package:dio/dio.dart';

import '../domain/character.dart';
import '../domain/character_repository.dart';

class DioCharacterRepository implements CharacterRepository {
  DioCharacterRepository(this._dio);

  final Dio _dio;

  @override
  Future<CharacterPage> getCharacters({
    required int page,
    required String name,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/character',
        queryParameters: {'page': page, if (name.isNotEmpty) 'name': name},
      );
      final data = response.data!;
      final info = data['info'] as Map<String, dynamic>;
      final next = info['next'] as String?;
      return CharacterPage(
        characters: (data['results'] as List<dynamic>)
            .map((item) => _characterFromJson(item as Map<String, dynamic>))
            .toList(),
        nextPage: next == null
            ? null
            : int.tryParse(Uri.parse(next).queryParameters['page'] ?? ''),
      );
    } on DioException catch (error) {
      // The API uses 404 when a name filter matches no characters.
      if (page == 1 && name.isNotEmpty && error.response?.statusCode == 404) {
        return const CharacterPage(characters: [], nextPage: null);
      }
      rethrow;
    }
  }

  Character _characterFromJson(Map<String, dynamic> json) => Character(
    id: json['id'] as int,
    name: json['name'] as String,
    status: json['status'] as String,
    species: json['species'] as String,
    origin: (json['origin'] as Map<String, dynamic>)['name'] as String,
    location: (json['location'] as Map<String, dynamic>)['name'] as String,
    imageUrl: json['image'] as String,
  );
}
