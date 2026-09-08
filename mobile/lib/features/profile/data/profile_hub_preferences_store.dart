import 'package:shared_preferences/shared_preferences.dart';

/// Profil hub — açık accordion bölümü tercihi.
class ProfileHubPreferencesStore {
  ProfileHubPreferencesStore(this._prefs);

  static const _openSectionKey = 'profile_hub_open_section_v1';

  final SharedPreferences _prefs;

  static Future<ProfileHubPreferencesStore> create() async {
    return ProfileHubPreferencesStore(await SharedPreferences.getInstance());
  }

  /// -1 = hepsi kapalı.
  int get openSectionIndex => _prefs.getInt(_openSectionKey) ?? 0;

  Future<void> setOpenSectionIndex(int index) async {
    await _prefs.setInt(_openSectionKey, index);
  }
}
