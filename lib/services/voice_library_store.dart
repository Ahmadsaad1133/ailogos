import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/voice_narration.dart';

/// Stores voice narrations locally using [SharedPreferences].
class VoiceLibraryStore {
  VoiceLibraryStore({required SharedPreferences preferences})
      : _preferences = preferences;

  static const _cachePrefix = 'voice.library';

  final SharedPreferences _preferences;

  String _keyForUser(String userId) => '$_cachePrefix.$userId';

  Future<List<VoiceNarration>> fetchNarrations(String userId) async {
    final raw = _preferences.getString(_keyForUser(userId));
    if (raw == null || raw.isEmpty) {
      return const <VoiceNarration>[];
    }
    try {
      final json = jsonDecode(raw) as List<dynamic>;
      final narrations = json
          .whereType<Map<String, dynamic>>()
          .map(VoiceNarration.fromJson)
          .toList();
      narrations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return narrations;
    } catch (_) {
      return const <VoiceNarration>[];
    }
  }

  Future<void> saveNarration(
      String userId,
      VoiceNarration narration,
      ) async {
    final existing = await fetchNarrations(userId);
    final filtered = existing
        .where((element) => element.id != narration.id)
        .toList(growable: true);
    filtered.insert(0, narration);
    final encoded = jsonEncode(filtered.map((e) => e.toJson()).toList());
    await _preferences.setString(_keyForUser(userId), encoded);
  }
}