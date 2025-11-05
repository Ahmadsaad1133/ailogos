import 'dart:convert';

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    this.favoriteGenre,
    this.personaKey,
  });

  final String id;
  final String name;
  final String? favoriteGenre;
  final String? personaKey;

  ChildProfile copyWith({
    String? id,
    String? name,
    String? favoriteGenre,
    String? personaKey,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
      personaKey: personaKey ?? this.personaKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'favoriteGenre': favoriteGenre,
      'personaKey': personaKey,
    };
  }

  static ChildProfile fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Explorer',
      favoriteGenre: json['favoriteGenre'] as String?,
      personaKey: json['personaKey'] as String?,
    );
  }

  static String encodeList(List<ChildProfile> profiles) {
    final raw = profiles.map((p) => p.toJson()).toList();
    return jsonEncode(raw);
  }

  static List<ChildProfile> decodeList(String? source) {
    if (source == null || source.isEmpty) {
      return const [];
    }

    try {
      final dynamic decoded = jsonDecode(source);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChildProfile.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}