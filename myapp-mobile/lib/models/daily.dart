import 'package:flutter/material.dart';

/// Daily項目の印（API の mark 値 → 表示する記号）
const dailyMarks = <String, String>{
  'star': '★',
  'circle': '●',
  'heart': '♥',
  'diamond': '◆',
  'triangle': '▲',
  'check': '✔',
};

/// Web版と同じ色のプリセット
const dailyColorPresets = <String>[
  '#facc15',
  '#f97316',
  '#ef4444',
  '#ec4899',
  '#a855f7',
  '#3b82f6',
  '#22d3ee',
  '#22c55e',
];

Color parseDailyColor(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (value == null) return Colors.amber;
  return Color(0xFF000000 | value);
}

class DailyItem {
  final int id;
  final String title;
  final String color;
  final String mark;
  final int order;
  final bool isActive;

  DailyItem({
    required this.id,
    required this.title,
    required this.color,
    required this.mark,
    required this.order,
    required this.isActive,
  });

  String get symbol => dailyMarks[mark] ?? '★';
  Color get displayColor => parseDailyColor(color);

  factory DailyItem.fromJson(Map<String, dynamic> json) {
    return DailyItem(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      color: (json['color'] as String?) ?? dailyColorPresets.first,
      mark: (json['mark'] as String?) ?? 'star',
      order: (json['order'] as int?) ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}
