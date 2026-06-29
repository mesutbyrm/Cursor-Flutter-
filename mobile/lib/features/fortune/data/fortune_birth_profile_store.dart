import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı doğum tarihi/saati — profil senkronu + yerel önbellek.
class FortuneBirthProfile {
  const FortuneBirthProfile({
    required this.birthDate,
    required this.birthTime,
  });

  final DateTime birthDate;
  final TimeOfDay birthTime;

  String get birthDateIso => DateFormat('yyyy-MM-dd').format(birthDate);

  String get birthTimeIso =>
      '${birthTime.hour.toString().padLeft(2, '0')}:${birthTime.minute.toString().padLeft(2, '0')}';

  Map<String, String> toJson() => {
        'birthDate': birthDateIso,
        'birthTime': birthTimeIso,
      };

  static FortuneBirthProfile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final dateRaw = json['birthDate']?.toString();
    final timeRaw = json['birthTime']?.toString();
    if (dateRaw == null || dateRaw.isEmpty) return null;
    final date = DateTime.tryParse(dateRaw);
    if (date == null) return null;
    TimeOfDay time = const TimeOfDay(hour: 12, minute: 0);
    if (timeRaw != null && timeRaw.contains(':')) {
      final parts = timeRaw.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 12;
        final m = int.tryParse(parts[1]) ?? 0;
        time = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
      }
    }
    return FortuneBirthProfile(birthDate: date, birthTime: time);
  }
}

class FortuneBirthProfileStore {
  FortuneBirthProfileStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<FortuneBirthProfileStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return FortuneBirthProfileStore(prefs);
  }

  String _key(String userId) => 'fortune_birth_profile_v1_$userId';

  FortuneBirthProfile? read(String userId) {
    final raw = _prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final parts = raw.split('|');
      if (parts.length < 2) return null;
      return FortuneBirthProfile.fromJson({
        'birthDate': parts[0],
        'birthTime': parts[1],
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userId, FortuneBirthProfile profile) async {
    await _prefs.setString(
      _key(userId),
      '${profile.birthDateIso}|${profile.birthTimeIso}',
    );
  }

  Future<void> clear(String userId) async {
    await _prefs.remove(_key(userId));
  }
}
