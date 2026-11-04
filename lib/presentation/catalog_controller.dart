import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dio_character_repository.dart';
import '../domain/character.dart';
import '../domain/character_repository.dart';

final characterRepositoryProvider = Provider<CharacterRepository>(
  (ref) => DioCharacterRepository(),
);

final catalogProvider = StateNotifierProvider<CatalogController, CatalogState>(
  (ref) => CatalogController(ref.read(characterRepositoryProvider)),
);

class CatalogState {
  const CatalogState({
    this.query = '',
    this.characters = const [],
    this.nextPage = 1,
    this.isInitialLoading = true,
    this.isPageLoading = false,
    this.hasError = false,
  });

  final String query;
  final List<Character> characters;
  final int? nextPage;
  final bool isInitialLoading;
  final bool isPageLoading;
  final bool hasError;

  bool get isEmpty => !isInitialLoading && !hasError && characters.isEmpty;

  CatalogState copyWith({
    List<Character>? characters,
    Object? nextPage = _unset,
    bool? isInitialLoading,
    bool? isPageLoading,
    bool? hasError,
  }) => CatalogState(
    query: query,
    characters: characters ?? this.characters,
    nextPage: identical(nextPage, _unset) ? this.nextPage : nextPage as int?,
    isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    isPageLoading: isPageLoading ?? this.isPageLoading,
    hasError: hasError ?? this.hasError,
  );

  static const _unset = Object();
}

class CatalogController extends StateNotifier<CatalogState> {
  CatalogController(
    this._repository, {
    this.debounce = const Duration(milliseconds: 350),
  }) : super(const CatalogState()) {
    unawaited(_fetch(page: 1, generation: _generation));
  }

  final CharacterRepository _repository;
  final Duration debounce;
  Timer? _searchTimer;
  int _generation = 0;

  void setQuery(String value) {
    final query = value.trim();
    if (query == state.query) return;
    _searchTimer?.cancel();
    final generation = ++_generation;
    state = CatalogState(query: query);
    _searchTimer = Timer(debounce, () {
      unawaited(_fetch(page: 1, generation: generation));
    });
  }

  void loadNextPage() {
    final page = state.nextPage;
    if (page == null ||
        state.isInitialLoading ||
        state.isPageLoading ||
        state.hasError) {
      return;
    }
    state = state.copyWith(isPageLoading: true);
    unawaited(_fetch(page: page, generation: _generation));
  }

  void retry() {
    if (!state.hasError) return;
    final firstPage = state.characters.isEmpty;
    state = state.copyWith(
      hasError: false,
      isInitialLoading: firstPage,
      isPageLoading: !firstPage,
    );
    unawaited(
      _fetch(page: firstPage ? 1 : state.nextPage!, generation: _generation),
    );
  }

  Future<void> _fetch({required int page, required int generation}) async {
    try {
      final result = await _repository.getCharacters(
        page: page,
        name: state.query,
      );
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
        characters: page == 1
            ? result.characters
            : [...state.characters, ...result.characters],
        nextPage: result.nextPage,
        isInitialLoading: false,
        isPageLoading: false,
        hasError: false,
      );
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
        isInitialLoading: false,
        isPageLoading: false,
        hasError: true,
      );
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
