import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../membership/membership_capability_providers.dart';
import '../util/json_util.dart';
import 'me_entitlements_providers.dart';
import 'vip_preferences_model.dart';

final vipPreferencesProvider =
    AsyncNotifierProvider.autoDispose<VipPreferencesNotifier, VipPreferences>(
  VipPreferencesNotifier.new,
);

class VipPreferencesNotifier extends AutoDisposeAsyncNotifier<VipPreferences> {
  @override
  Future<VipPreferences> build() async {
    final raw = await ref.read(meEntitlementsRemoteProvider).fetchVipPreferences();
    final data = raw['preferences'] is Map
        ? asJsonMap(raw['preferences'])
        : raw;
    return VipPreferences.fromJson(data);
  }

  Future<void> savePrefs(VipPreferences next) async {
    final remote = ref.read(meEntitlementsRemoteProvider);
    final res = await remote.updateVipPreferences(next.toJson());
    final data = res['preferences'] is Map
        ? asJsonMap(res['preferences'])
        : res;
    final parsed = VipPreferences.fromJson(data);
    state = AsyncData(parsed);
    ref.invalidate(membershipCapabilitiesProvider);
    ref.invalidate(meMembershipPackageProvider);
  }
}
