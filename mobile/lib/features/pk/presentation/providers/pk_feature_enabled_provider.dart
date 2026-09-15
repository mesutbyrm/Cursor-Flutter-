import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bootstrap/mobile_config_providers.dart';

/// Üretim `PK_ENABLED` — `GET /api/mobile/config` → `features.pkBattle`.
final pkFeatureEnabledProvider = Provider<bool>((ref) {
  return ref.watch(mobileFeatureFlagsProvider).pkBattle;
});
