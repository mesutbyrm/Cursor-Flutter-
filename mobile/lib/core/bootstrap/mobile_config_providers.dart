import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_build_info.dart';
import '../config/mobile_config_remote_datasource.dart';
import '../config/models/mobile_config.dart';
import '../../features/auth/presentation/providers/auth_service_provider.dart';
import 'startup_perf.dart';

String mobileConfigPlatform() {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'unknown';
}

final mobileConfigRemoteProvider = Provider<MobileConfigRemoteDataSource>((ref) {
  return MobileConfigRemoteDataSource(publicDio: ref.watch(authPublicDioProvider));
});

/// Uygulama açılışında `GET /api/mobile/config` — ilk kareden sonra.
final mobileConfigProvider = FutureProvider<MobileConfig>((ref) async {
  await Future<void>.delayed(StartupPerf.mobileConfigDelay);
  final response = await ref.watch(mobileConfigRemoteProvider).getConfig(
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
