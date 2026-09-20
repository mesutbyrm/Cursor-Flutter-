import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Admin activity monitoring — suspicious user behaviors.
final adminSuspiciousActivityProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/suspicious',
      query: {'limit': '50'},
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

/// Bekleyen suspicious activity sayısı.
final adminSuspiciousActivityCountProvider = Provider<int>((ref) {
  final activities = ref.watch(adminSuspiciousActivityProvider).valueOrNull ?? [];
  return activities.where((a) => a['reviewed'] != true).length;
});

/// Uyarılı / yasaklı kullanıcılar.
final adminWarnedUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/moderation',
      query: {'status': 'warned,banned', 'limit': '50'},
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

/// Uyarılı/yasaklı kullanıcı sayısı.
final adminWarnedUsersCountProvider = Provider<int>((ref) {
  final users = ref.watch(adminWarnedUsersProvider).valueOrNull ?? [];
  return users.length;
});

/// Toplam activity monitoring işleri.
final adminActivityMonitoringCountProvider = Provider<int>((ref) {
  final suspicious = ref.watch(adminSuspiciousActivityCountProvider);
  final warned = ref.watch(adminWarnedUsersCountProvider);
  return suspicious + warned;
});

/// Activity types.
enum SuspiciousActivityType {
  rapidLogin,      // Birden çok IP'den hızlı giriş
  unusualSpending, // Çok hızlı para akışı
  massFollow,      // Toplu takip
  spamReport,      // Çok rapor almış
  other,
}

SuspiciousActivityType parseSuspiciousType(String? type) {
  switch (type?.toLowerCase()) {
    case 'rapid_login':
      return SuspiciousActivityType.rapidLogin;
    case 'unusual_spending':
      return SuspiciousActivityType.unusualSpending;
    case 'mass_follow':
      return SuspiciousActivityType.massFollow;
    case 'spam_report':
      return SuspiciousActivityType.spamReport;
    default:
      return SuspiciousActivityType.other;
  }
}

String activityTypeLabel(SuspiciousActivityType type) {
  switch (type) {
    case SuspiciousActivityType.rapidLogin:
      return 'Hızlı giriş';
    case SuspiciousActivityType.unusualSpending:
      return 'Anormal harcama';
    case SuspiciousActivityType.massFollow:
      return 'Toplu takip';
    case SuspiciousActivityType.spamReport:
      return 'Spam rapor';
    case SuspiciousActivityType.other:
      return 'Diğer';
  }
}
