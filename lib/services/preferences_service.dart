import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService(this._preferences);

  final SharedPreferences _preferences;

  static const _onboardingKey = 'onboarding_complete';
  static const _displayNameKey = 'display_name';
  static const _accentKey = 'accent_hex';

  bool get onboardingComplete => _preferences.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingComplete(bool value) async {
    await _preferences.setBool(_onboardingKey, value);
  }

  String? get displayName => _preferences.getString(_displayNameKey);

  Future<void> setDisplayName(String value) async {
    await _preferences.setString(_displayNameKey, value);
  }

  int? get accentHex => _preferences.getInt(_accentKey);

  Future<void> setAccentHex(int value) async {
    await _preferences.setInt(_accentKey, value);
  }
}