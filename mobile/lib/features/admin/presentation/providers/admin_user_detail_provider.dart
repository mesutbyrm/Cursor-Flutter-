import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../gifts/data/gift_insights_remote_datasource.dart';
import '../../../gifts/domain/gift_collection.dart';
import '../../domain/admin_user_detail.dart';
import 'admin_panel_providers.dart';
import 'staff_access_provider.dart';

class AdminUserBundle {
  const AdminUserBundle({
    required this.detail,
    this.financeHistory = const [],
    this.activities = const [],
    this.giftCollection,
    this.giftAlbum,
    this.loadWarnings = const [],
  });

  final AdminUserDetail detail;
  final List<Map<String, dynamic>> financeHistory;
  final List<Map<String, dynamic>> activities;
  final GiftCollection? giftCollection;
  final GiftAlbum? giftAlbum;
  final List<String> loadWarnings;
}

final adminUserDetailProvider = FutureProvider.autoDispose
    .family<AdminUserBundle, String>((ref, userId) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManageUsers &&
      !access.canManagePayments &&
      !access.canModerate) {
    return AdminUserBundle(
      detail: AdminUserDetail.fromMaps(userId: userId),
      loadWarnings: const ['Yetkiniz yok'],
    );
  }

  final remote = ref.watch(adminRemoteProvider);
  final dio = ref.watch(dioProvider);
  final gifts = GiftInsightsRemoteDataSource(dio);
  final warnings = <String>[];

  Map<String, dynamic> admin = {};
  Map<String, dynamic> public = {};

  try {
    admin = await remote.fetchUser(userId);
  } catch (_) {
    warnings.add('Admin kullanıcı kaydı yüklenemedi');
  }

  try {
    final res = await dio.safeGet<dynamic>(
      ApiEndpoints.userProfile(userId),
      forceRefresh: true,
    );
    if (res.data is Map) {
      public = asJsonMap(res.data);
      final nested = pick(public, ['user', 'data', 'profile']);
      if (nested is Map) public = {...public, ...asJsonMap(nested)};
    }
  } catch (_) {
    warnings.add('Genel profil yüklenemedi');
  }

  final detail = AdminUserDetail.fromMaps(
    userId: userId,
    admin: admin,
    publicProfile: public,
  );

  var finance = const <Map<String, dynamic>>[];
  if (access.canManagePayments) {
    try {
      finance = await remote.fetchUserFinanceHistory(userId: userId, limit: 80);
    } catch (_) {
      warnings.add('Finans geçmişi yüklenemedi');
    }
  }

  var activities = const <Map<String, dynamic>>[];
  try {
    final all = await remote.fetchActivities(limit: 120);
    activities = all.where((a) {
      final uid = pick(a, ['userId', 'targetUserId'])?.toString() ?? '';
      if (uid == userId) return true;
      final user = a['user'];
      if (user is Map) {
        final id = pick(asJsonMap(user), ['id', 'userId'])?.toString() ?? '';
        if (id == userId) return true;
      }
      return false;
    }).take(40).toList(growable: false);
  } catch (_) {
    warnings.add('Aktivite akışı yüklenemedi');
  }

  GiftCollection? collection;
  GiftAlbum? album;
  try {
    collection = await gifts.fetchCollection(userId);
    album = await gifts.fetchAlbum(userId);
  } catch (_) {
    warnings.add('Hediye koleksiyonu yüklenemedi');
  }

  return AdminUserBundle(
    detail: detail,
    financeHistory: finance,
    activities: activities,
    giftCollection: collection,
    giftAlbum: album,
    loadWarnings: warnings,
  );
});
