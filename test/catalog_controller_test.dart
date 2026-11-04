import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rick_morty_flutter_app/domain/character.dart';
import 'package:rick_morty_flutter_app/domain/character_repository.dart';
import 'package:rick_morty_flutter_app/presentation/catalog_controller.dart';

void main() {
  test('search debounces and ignores responses from older queries', () async {
    final repository = FakeRepository();
    final controller = CatalogController(
      repository,
      debounce: const Duration(milliseconds: 10),
    );
    expect(repository.requests.single.name, '');

    controller.setQuery('ri');
    controller.setQuery('rick');
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(repository.requests.map((r) => r.name), ['', 'rick']);

    controller.setQuery('morty');
    await Future<void>.delayed(const Duration(milliseconds: 25));
    repository.complete(1, [character(1, 'Rick')]);
    repository.complete(0, [character(2, 'Old result')]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.query, 'morty');
    expect(controller.state.isInitialLoading, isTrue);
    expect(controller.state.characters, isEmpty);

    repository.complete(2, [character(3, 'Morty')]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.characters.single.name, 'Morty');
    controller.dispose();
  });

  test(
    'pagination requests each page once and retries a failed page',
    () async {
      final repository = FakeRepository();
      final controller = CatalogController(repository);
      repository.complete(0, [character(1, 'Rick')], nextPage: 2);
      await Future<void>.delayed(Duration.zero);

      controller.loadNextPage();
      controller.loadNextPage();
      expect(repository.requests.map((r) => r.page), [1, 2]);
      expect(controller.state.isPageLoading, isTrue);

      repository.fail(1);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.hasError, isTrue);
      expect(controller.state.characters.single.name, 'Rick');
      controller.loadNextPage();
      expect(repository.requests.length, 2);

      controller.retry();
      expect(repository.requests.map((r) => r.page), [1, 2, 2]);
      repository.complete(2, [character(2, 'Morty')]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.characters.map((c) => c.name), ['Rick', 'Morty']);
      expect(controller.state.nextPage, isNull);
      controller.loadNextPage();
      expect(repository.requests.length, 3);
      controller.dispose();
    },
  );

  test('first-page failure can be retried', () async {
    final repository = FakeRepository();
    final controller = CatalogController(repository);
    expect(controller.state.isInitialLoading, isTrue);
    repository.fail(0);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.hasError, isTrue);
    expect(controller.state.isInitialLoading, isFalse);

    controller.retry();
    expect(controller.state.isInitialLoading, isTrue);
    expect(repository.requests.map((r) => r.page), [1, 1]);
    repository.complete(1, [character(1, 'Rick')]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.characters.single.name, 'Rick');
    expect(controller.state.hasError, isFalse);
    controller.dispose();
  });

  test('empty search result is distinct from a load error', () async {
    final repository = FakeRepository();
    final controller = CatalogController(
      repository,
      debounce: const Duration(milliseconds: 10),
    );
    repository.complete(0, [character(1, 'Rick')]);
    await Future<void>.delayed(Duration.zero);
    controller.setQuery('nobody');
    await Future<void>.delayed(const Duration(milliseconds: 25));
    repository.complete(1, []);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.isEmpty, isTrue);
    expect(controller.state.hasError, isFalse);
    controller.dispose();
  });
}

Character character(int id, String name) => Character(
  id: id,
  name: name,
  status: 'Alive',
  species: 'Human',
  origin: 'Earth',
  location: 'Citadel',
  imageUrl: '',
);

class Request {
  Request(this.page, this.name);
  final int page;
  final String name;
}

class FakeRepository implements CharacterRepository {
  final requests = <Request>[];
  final _pending = <Completer<CharacterPage>>[];

  @override
  Future<CharacterPage> getCharacters({
    required int page,
    required String name,
  }) {
    requests.add(Request(page, name));
    final completer = Completer<CharacterPage>();
    _pending.add(completer);
    return completer.future;
  }

  void complete(int index, List<Character> characters, {int? nextPage}) {
    _pending[index].complete(
      CharacterPage(characters: characters, nextPage: nextPage),
    );
  }

  void fail(int index) => _pending[index].completeError(Exception('network'));
}
