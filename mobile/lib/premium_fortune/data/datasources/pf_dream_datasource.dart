import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/pf_dream_reading.dart';
import 'openai_datasource.dart';

class PfDreamDatasource {
  PfDreamDatasource({OpenAiDatasource? openAi})
      : _openAi = openAi ?? OpenAiDatasource(),
        _uuid = const Uuid();

  final OpenAiDatasource _openAi;
  final Uuid _uuid;

  Future<List<PfDreamReading>> getHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('pf_dream_$userId') ?? [];
    return raw.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return PfDreamReading(
        id: m['id'] as String,
        userId: userId,
        dreamText: m['dreamText'] as String? ?? '',
        interpretation: m['interpretation'] as String? ?? '',
        symbols: List<String>.from(m['symbols'] as List? ?? []),
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<PfDreamReading> interpretDream({
    required String userId,
    required String dreamText,
  }) async {
    final interpretation = await _openAi.interpretDream(dreamText);
    final symbols = _extractSymbols(dreamText);

    final reading = PfDreamReading(
      id: _uuid.v4(),
      userId: userId,
      dreamText: dreamText,
      interpretation: interpretation,
      symbols: symbols,
      createdAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    final key = 'pf_dream_$userId';
    final list = prefs.getStringList(key) ?? [];
    list.insert(
      0,
      jsonEncode({
        'id': reading.id,
        'dreamText': dreamText,
        'interpretation': interpretation,
        'symbols': symbols,
        'createdAt': reading.createdAt.toIso8601String(),
      }),
    );
    await prefs.setStringList(key, list.take(30).toList());

    return reading;
  }

  List<String> _extractSymbols(String text) {
    const keywords = [
      'su', 'ateş', 'uçmak', 'düşmek', 'yılan', 'köpek', 'kedi',
      'bebek', 'ölüm', 'ev', 'araba', 'deniz', 'dağ', 'ağaç',
    ];
    final lower = text.toLowerCase();
    return keywords.where((k) => lower.contains(k)).take(5).toList();
  }
}
