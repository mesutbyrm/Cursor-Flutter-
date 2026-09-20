import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Sistem yapılandırması.
final adminSystemConfigProvider =
    FutureProvider.autoDispose<SystemConfig>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/system-config',
    );
    if (res.data is Map) {
      return SystemConfig.fromJson(res.data as Map<String, dynamic>);
    }
    return const SystemConfig();
  } catch (e) {
    return const SystemConfig();
  }
});

/// Sistem yapılandırması verisi.
class SystemConfig {
  final bool maintenanceMode;
  final bool newRegistrationsEnabled;
  final int maxLoginAttempts;
  final int sessionTimeoutMinutes;
  final double minimumWithdrawalAmount;
  final double maximumWithdrawalAmount;
  final int rateLimit; // requests per minute
  final bool emailVerificationRequired;
  final bool twoFactorAuthRequired;
  final List<String> blockedCountries;

  const SystemConfig({
    this.maintenanceMode = false,
    this.newRegistrationsEnabled = true,
    this.maxLoginAttempts = 5,
    this.sessionTimeoutMinutes = 30,
    this.minimumWithdrawalAmount = 10.0,
    this.maximumWithdrawalAmount = 10000.0,
    this.rateLimit = 100,
    this.emailVerificationRequired = true,
    this.twoFactorAuthRequired = false,
    this.blockedCountries = const [],
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      newRegistrationsEnabled: json['new_registrations_enabled'] as bool? ?? true,
      maxLoginAttempts: json['max_login_attempts'] as int? ?? 5,
      sessionTimeoutMinutes: json['session_timeout_minutes'] as int? ?? 30,
      minimumWithdrawalAmount:
          (json['minimum_withdrawal_amount'] as num?)?.toDouble() ?? 10.0,
      maximumWithdrawalAmount:
          (json['maximum_withdrawal_amount'] as num?)?.toDouble() ?? 10000.0,
      rateLimit: json['rate_limit'] as int? ?? 100,
      emailVerificationRequired: json['email_verification_required'] as bool? ?? true,
      twoFactorAuthRequired: json['two_factor_auth_required'] as bool? ?? false,
      blockedCountries:
          List<String>.from(json['blocked_countries'] as List? ?? []),
    );
  }
}

/// Özellik bayrakları.
final adminFeatureFlagsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/feature-flags',
    );
    if (res.data is List) {
      return List<Map<String, dynamic>>.from(
        (res.data as List).map((e) => e is Map ? e : {}),
      );
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// API anahtarları.
final adminApiKeysProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/api-keys',
    );
    if (res.data is List) {
      return List<Map<String, dynamic>>.from(
        (res.data as List).map((e) => e is Map ? e : {}),
      );
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// API anahtarı sayısı.
final adminApiKeyCountProvider = Provider<int>((ref) {
  final keys = ref.watch(adminApiKeysProvider).valueOrNull ?? [];
  return keys.length;
});
