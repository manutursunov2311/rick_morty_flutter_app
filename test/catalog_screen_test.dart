import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rick_morty_flutter_app/domain/character.dart';
import 'package:rick_morty_flutter_app/domain/character_repository.dart';
import 'package:rick_morty_flutter_app/presentation/catalog_controller.dart';
import 'package:rick_morty_flutter_app/presentation/catalog_screen.dart';

void main() {
  testWidgets('search works while the first page is still loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(PendingRepository()),
        ],
        child: const MaterialApp(home: CatalogScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Morty');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog renders on a wide window', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(StubRepository()),
        ],
        child: const MaterialApp(home: CatalogScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Rick 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search and scroll position survive a details round trip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(StubRepository()),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const CatalogScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), 'Rick');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Rick 0'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 400));
    final before = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(before, greaterThan(0));

    await tester.tap(find.byType(Card).at(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Персонаж'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Rick',
    );
    final after = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(after, closeTo(before, 1));
    expect(tester.takeException(), isNull);
  });
}

class StubRepository implements CharacterRepository {
  @override
  Future<CharacterPage> getCharacters({
    required int page,
    required String name,
  }) async {
    return CharacterPage(
      characters: List.generate(
        20,
        (index) => Character(
          id: index,
          name: 'Rick $index',
          status: 'Alive',
          species: 'Human',
          origin: 'Earth',
          location: 'Citadel',
          imageUrl: '',
        ),
      ),
      nextPage: null,
    );
  }
}

class PendingRepository implements CharacterRepository {
  @override
  Future<CharacterPage> getCharacters({
    required int page,
    required String name,
  }) => Completer<CharacterPage>().future;
}
