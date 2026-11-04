import 'character.dart';

class CharacterPage {
  const CharacterPage({required this.characters, required this.nextPage});

  final List<Character> characters;
  final int? nextPage;
}

abstract class CharacterRepository {
  Future<CharacterPage> getCharacters({
    required int page,
    required String name,
  });
}
