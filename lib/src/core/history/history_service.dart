import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HistoryEvent {
  const HistoryEvent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.value,
  });

  final String type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final num? value;

  Map<String, Object?> toJson() => {
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'createdAt': createdAt.toIso8601String(),
        'value': value,
      };

  factory HistoryEvent.fromJson(Map<String, dynamic> json) => HistoryEvent(
        type: json['type'] as String? ?? 'unknown',
        title: json['title'] as String? ?? 'رویداد',
        subtitle: json['subtitle'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        value: json['value'] as num?,
      );
}

class HistoryService {
  const HistoryService();

  static const _key = 'padra.history.v1';
  static const _maxEvents = 150;

  Future<List<HistoryEvent>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final events = <HistoryEvent>[];
    for (final item in raw) {
      try {
        events.add(HistoryEvent.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {
        continue;
      }
    }
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return events;
  }

  Future<void> add(HistoryEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final next = <HistoryEvent>[event, ...current].take(_maxEvents).toList(growable: false);
    await prefs.setStringList(
      _key,
      next.map((e) => jsonEncode(e.toJson())).toList(growable: false),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
