import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class StatusLabel extends StatelessWidget {
  const StatusLabel({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status.toLowerCase()) {
      'alive' => ('Жив', AppTheme.alive),
      'dead' => ('Мёртв', AppTheme.dead),
      _ => ('Неизвестно', AppTheme.unknown),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
