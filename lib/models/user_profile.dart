import 'dart:convert';

/// Representation of the user's profile and personalization settings
/// that can be synchronized to a remote backend.
class UserProfile {
  UserProfile({
    required this.userId,
    this.displayName,
    this.accentHex,
    this.onboardingComplete = false,
    DateTime? updatedAt,
  }) : updatedAt = (updatedAt ?? DateTime.now()).toUtc();


  factory UserProfile.anonymous(String userId) {
    return UserProfile(userId: userId);
  }

  final String userId;
  final String? displayName;
  final int? accentHex;
  final bool onboardingComplete;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? userId,
    String? displayName,
    int? accentHex,
    bool? onboardingComplete,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      accentHex: accentHex ?? this.accentHex,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'accentHex': accentHex,
      'onboardingComplete': onboardingComplete,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String?,
      accentHex: json['accentHex'] as int?,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toRemoteJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'accent_hex': accentHex,
      'onboarding_complete': onboardingComplete,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromRemoteJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String?,
      accentHex: json['accent_hex'] as int?,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static String encode(UserProfile profile) {
    return jsonEncode(profile.toJson());
  }

  static UserProfile decode(String source) {
    if (source.isEmpty) {
      throw const FormatException('Empty profile payload');
    }
    final dynamic decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid profile payload');
    }
    return UserProfile.fromJson(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}