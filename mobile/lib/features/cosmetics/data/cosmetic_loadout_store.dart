import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cosmetic_slot.dart';
import '../domain/user_cosmetic_loadout.dart';

/// Gold kullanıcı kozmetik seçimleri — backend equip API gelene kadar yerel.
class CosmeticLoadoutStore {
  CosmeticLoadoutStore(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String userId) => 'cosmetic_loadout_$userId';

  Future<UserCosmeticLoadout> read(String userId) async {
    if (userId.isEmpty) return const UserCosmeticLoadout.empty();
    final raw = _prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return const UserCosmeticLoadout.empty();
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const UserCosmeticLoadout.empty();
      final equipped = <CosmeticSlot, String>{};
      for (final slot in CosmeticSlot.values) {
        final id = map[slot.apiKey];
        if (id != null && id.toString().trim().isNotEmpty) {
          equipped[slot] = id.toString().trim();
        }
      }
      return UserCosmeticLoadout(equipped: equipped);
    } catch (_) {
      return const UserCosmeticLoadout.empty();
    }
  }

  Future<void> write(String userId, UserCosmeticLoadout loadout) async {
    if (userId.isEmpty) return;
    await _prefs.setString(
      _key(userId),
      jsonEncode(loadout.toStorageJson()),
    );
  }
}
