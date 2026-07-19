import 'package:equatable/equatable.dart';

import 'cosmetic_slot.dart';

class UserCosmeticLoadout extends Equatable {
  const UserCosmeticLoadout({
    this.equipped = const {},
  });

  const UserCosmeticLoadout.empty() : equipped = const {};

  factory UserCosmeticLoadout.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserCosmeticLoadout.empty();
    final raw = json['equipped'] ?? json;
    final map = <CosmeticSlot, String>{};
    if (raw is Map) {
      for (final slot in CosmeticSlot.values) {
        final id = raw[slot.apiKey] ?? raw[slot.name];
        if (id != null && id.toString().trim().isNotEmpty) {
          map[slot] = id.toString().trim();
        }
      }
    }
    return UserCosmeticLoadout(equipped: map);
  }

  final Map<CosmeticSlot, String> equipped;

  String? idFor(CosmeticSlot slot) => equipped[slot];

  UserCosmeticLoadout copyWithEquipped(CosmeticSlot slot, String? itemId) {
    final next = Map<CosmeticSlot, String>.from(equipped);
    if (itemId == null || itemId.isEmpty) {
      next.remove(slot);
    } else {
      next[slot] = itemId;
    }
    return UserCosmeticLoadout(equipped: next);
  }

  Map<String, dynamic> toStorageJson() => {
        for (final e in equipped.entries) e.key.apiKey: e.value,
      };

  @override
  List<Object?> get props => [equipped];
}
