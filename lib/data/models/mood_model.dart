import 'package:flutter/material.dart';

class MoodModel {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  final Color bgColor;
  final int order;
  final bool isActive;

  MoodModel({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.order,
    required this.isActive,
  });

  factory MoodModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MoodModel(
      id: id,
      label: data['label'] ?? '',
      emoji: data['emoji'] ?? '🌸',
      color: _hexToColor(data['color'] ?? '#F48FB1'),
      bgColor: _hexToColor(data['bgColor'] ?? '#FCE4EC'),
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  static Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Map<String, dynamic> toHive() => {
        'id': id,
        'label': label,
        'emoji': emoji,
        'color': color.value.toString(),
        'bgColor': bgColor.value.toString(),
        'order': order,
        'isActive': isActive,
      };

  factory MoodModel.fromHive(Map<String, dynamic> data) {
    return MoodModel(
      id: data['id'] ?? '',
      label: data['label'] ?? '',
      emoji: data['emoji'] ?? '🌸',
      color: Color(int.parse(data['color'] ?? '0xFFF48FB1')),
      bgColor: Color(int.parse(data['bgColor'] ?? '0xFFFCE4EC')),
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
}