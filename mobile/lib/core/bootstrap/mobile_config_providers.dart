import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_build_info.dart';
import 'startup_perf.dart';
import '../../services/models/mobile_config.dart';
import '../../services/services_providers.dart';

String mobileConfigPlatform() {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'unknown';
}

/// Uygulama açılışında `GET /api/mobile/config` — ilk kareden sonra.
final mobileConfigProvider = FutureProvider<MobileConfig>((ref) async {
  await Future<void>.delayed(StartupPerf.mobileConfigDelay);
  final service = ref.watch(configServiceProvider);
  final response = await service.getConfig(
    platform: mobileConfigPlatform(),
    version: AppBuildInfo.versionName,
  );
  return response.data ?? MobileConfig.parseRoot(null);
});

/// `features.*` bayrakları — navigasyon / modül görünürlüğü için.
final mobileFeatureFlagsProvider = Provider<MobileConfigFeatures>((ref) {
  return ref.watch(mobileConfigProvider).valueOrNull?.features ??
      const MobileConfigFeatures();
});
