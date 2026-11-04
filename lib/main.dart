import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_config.dart';
import 'app/app_theme.dart';
import 'data/dio_character_repository.dart';
import 'presentation/catalog_controller.dart';
import 'presentation/catalog_screen.dart';

void main() => runApp(
  ProviderScope(
    overrides: [
      characterRepositoryProvider.overrideWith((ref) {
        final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
        ref.onDispose(dio.close);
        return DioCharacterRepository(dio);
      }),
    ],
    child: const RickMortyApp(),
  ),
);

class RickMortyApp extends StatelessWidget {
  const RickMortyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick and Morty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const CatalogScreen(),
    );
  }
}
