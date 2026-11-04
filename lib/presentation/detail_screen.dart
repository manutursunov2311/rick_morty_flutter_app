import 'package:flutter/material.dart';

import '../domain/character.dart';
import 'character_image.dart';
import 'status_label.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Персонаж')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) => CharacterImage(
                      url: character.imageUrl,
                      size: constraints.maxWidth.clamp(0.0, 320.0),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(character.name, style: text.headlineMedium),
                const SizedBox(height: 12),
                StatusLabel(status: character.status),
                const SizedBox(height: 24),
                _DetailField(label: 'Вид', value: character.species),
                _DetailField(label: 'Происхождение', value: character.origin),
                _DetailField(
                  label: 'Текущая локация',
                  value: character.location,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: text.bodyLarge),
        ],
      ),
    );
  }
}
