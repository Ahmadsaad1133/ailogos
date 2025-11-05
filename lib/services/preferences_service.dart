import '../models/user_profile.dart';
import 'user_data_store.dart';

class PreferencesService {
  PreferencesService(this._store);
  final UserDataStore _store;

  Stream<UserProfile> get profileStream => _store.profileStream;

  Future<UserProfile> loadProfile() {
    return _store.fetchProfile();
  }

  Future<void> setOnboardingComplete(bool value) {
    return _store.updateProfile(onboardingComplete: value);
  }

  Future<void> setDisplayName(String value) {
    return _store.updateProfile(displayName: value);
  }

  Future<void> setAccentHex(int value) {
    return _store.updateProfile(accentHex: value);
  }
}