import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/generation_record.dart';

class HistoryService {
  HistoryService(this._preferences);

  final SharedPreferences _preferences;

  static const _storageKey = 'generation_history';

  List<GenerationRecord> loadHistory() {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) => GenerationRecord.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<GenerationRecord> history) async {
    final encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await _preferences.setString(_storageKey, encoded);
  }
}