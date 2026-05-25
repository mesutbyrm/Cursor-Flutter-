import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../membership/data/membership_remote_datasource.dart';
import '../../../membership/domain/membership_package_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/vip_tier.dart';

final vipTierProvider = Provider.autoDispose<VipTier>((ref) {
  final balances = ref.watch(walletBalancesProvider).valueOrNull;
  return VipTier.fromMembership(balances?.membership);
});

final vipMembershipDaysProvider = Provider.autoDispose<int?>((ref) {
  return ref.watch(walletBalancesProvider).valueOrNull?.membershipDaysRemaining;
});

/// Şifreli odalar — oturum içi kilidi açılmış oda id'leri.
class VipUnlockedRooms extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void unlock(String roomKey) {
    state = {...state, roomKey};
  }

  bool isUnlocked(String roomKey) => state.contains(roomKey);
}

final vipUnlockedRoomsProvider =
    NotifierProvider<VipUnlockedRooms, Set<String>>(
  VipUnlockedRooms.new,
);

/// Kullanıcının VIP odasına girebilir mi?
bool canEnterVipRoom(VipTier tier) => tier.index >= VipTier.gold.index;
