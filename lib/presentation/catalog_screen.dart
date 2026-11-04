import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/character.dart';
import 'catalog_controller.dart';
import 'character_image.dart';
import 'detail_screen.dart';
import 'status_label.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(catalogProvider).query,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      ref.read(catalogProvider.notifier).loadNextPage();
    }
  }

  void _resetScroll() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rick and Morty')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(catalogProvider.notifier).setQuery(value);
                      _resetScroll();
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Поиск по имени',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: state.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Очистить поиск',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(catalogProvider.notifier).setQuery('');
                                _resetScroll();
                              },
                            ),
                    ),
                  ),
                ),
                Expanded(child: _body(state)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(CatalogState state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.hasError && state.characters.isEmpty) {
      return _Message(
        message: 'Не удалось загрузить персонажей',
        onRetry: () => ref.read(catalogProvider.notifier).retry(),
      );
    }
    if (state.isEmpty) {
      return const _Message(message: 'Персонажи не найдены');
    }
    final showFooter = state.isPageLoading || state.hasError;
    return ListView.builder(
      controller: _scrollController,
      key: const PageStorageKey('characters'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: state.characters.length + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.characters.length) {
          if (state.isPageLoading) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _Message(
            message: 'Не удалось загрузить следующую страницу',
            onRetry: () => ref.read(catalogProvider.notifier).retry(),
          );
        }
        return _CharacterCard(character: state.characters[index]);
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DetailScreen(character: character),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageSize = constraints.maxWidth < 320 ? 76.0 : 104.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CharacterImage(url: character.imageUrl, size: imageSize),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character.name,
                          style: text.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        StatusLabel(status: character.status),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
