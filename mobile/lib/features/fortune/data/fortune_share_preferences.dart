import 'package:shared_preferences/shared_preferences.dart';

/// Otomatik fal paylaşım görünürlüğü.
enum FortuneAutoShareMode {
  off,
  profileOnly,
  followers,
  public;

  String get label => switch (this) {
        FortuneAutoShareMode.off => 'Kapalı',
        FortuneAutoShareMode.profileOnly => 'Sadece Profilim',
        FortuneAutoShareMode.followers => 'Takipçilerim',
        FortuneAutoShareMode.public => 'Herkese Açık',
      };

  static FortuneAutoShareMode fromKey(String? raw) => switch (raw) {
        'off' => FortuneAutoShareMode.off,
        'profile' => FortuneAutoShareMode.profileOnly,
        'followers' => FortuneAutoShareMode.followers,
        'public' => FortuneAutoShareMode.public,
        null => FortuneAutoShareMode.public,
        _ => FortuneAutoShareMode.off,
      };

  String get storageKey => switch (this) {
        FortuneAutoShareMode.off => 'off',
        FortuneAutoShareMode.profileOnly => 'profile',
        FortuneAutoShareMode.followers => 'followers',
        FortuneAutoShareMode.public => 'public',
      };

  /// API görünürlük alanı (sunucu yoksa yine de gönderilir).
  String? get apiVisibility => switch (this) {
        FortuneAutoShareMode.off => null,
        FortuneAutoShareMode.profileOnly => 'profile',
        FortuneAutoShareMode.followers => 'followers',
        FortuneAutoShareMode.public => 'public',
      };
}

class FortuneSharePreferences {
  FortuneSharePreferences(this._prefs);

  static const _key = 'fortune_auto_share_mode_v1';

  final SharedPreferences _prefs;

  static Future<FortuneSharePreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return FortuneSharePreferences(prefs);
  }

  FortuneAutoShareMode get autoShareMode =>
      FortuneAutoShareMode.fromKey(_prefs.getString(_key));

  Future<void> setAutoShareMode(FortuneAutoShareMode mode) async {
    await _prefs.setString(_key, mode.storageKey);
  }
}
