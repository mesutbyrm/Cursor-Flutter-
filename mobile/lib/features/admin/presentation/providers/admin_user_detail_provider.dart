import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../gifts/data/gift_insights_remote_datasource.dart';
import '../../../gifts/domain/gift_collection.dart';
import '../../domain/admin_user_detail.dart';
import '../../domain/admin_user_extended_data.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/admin_site_animation_providers.dart';
import 'staff_access_provider.dart';

class AdminUserBundle {
  const AdminUserBundle({
    required this.detail,
    this.financeHistory = const [],
    this.activities = const [],
    this.giftCollection,
    this.giftAlbum,
    this.giftLedger = const [],
    this.streamHistory = const [],
    this.roomHistory = const [],
    this.liveTeller,
    this.pendingPayments = const [],
    this.pkBanned = false,
    this.siteAnimationSlots = const {},
    this.loadWarnings = const [],
  });

  final AdminUserDetail detail;
  final List<Map<String, dynamic>> financeHistory;
  final List<Map<String, dynamic>> activities;
  final GiftCollection? giftCollection;
  final GiftAlbum? giftAlbum;
  final List<AdminGiftLedgerRow> giftLedger;
  final List<AdminBroadcastHistoryRow> streamHistory;
  final List<AdminBroadcastHistoryRow> roomHistory;
  final AdminLiveTellerSummary? liveTeller;
  final List<Map<String, dynamic>> pendingPayments;
  final bool pkBanned;
  final Map<String, String?> siteAnimationSlots;
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
  Map<String, dynamic>? fullProfile;

  try {
    fullProfile = await remote.tryFetchUserFull(userId);
    if (fullProfile != null) {
      admin = {...admin, ...fullProfile};
    }
  } catch (_) {
    warnings.add('Tam profil API yüklenemedi');
  }

  try {
    admin = {...admin, ...await remote.fetchUser(userId)};
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
    stats: fullProfile,
  );

  var adsWatched = detail.adsWatched;
  if (adsWatched == 0) {
    try {
      final ads = await remote.tryFetchUserAdsWatched(userId);
      if (ads != null && ads > 0) {
        adsWatched = ads;
      }
    } catch (_) {}
  }

  final enrichedDetail = AdminUserDetail.fromMaps(
    userId: userId,
    admin: {...detail.raw, if (adsWatched > 0) 'adsWatched': adsWatched},
    publicProfile: public,
    stats: fullProfile,
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

  var giftLedger = const <AdminGiftLedgerRow>[];
  if (access.canManagePayments || access.canModerate || access.canManageGifts) {
    try {
      giftLedger = await remote.fetchUserGiftLedger(userId);
    } catch (_) {
      warnings.add('Hediye defteri yüklenemedi');
    }
  }

  var streamHistory = const <AdminBroadcastHistoryRow>[];
  var roomHistory = const <AdminBroadcastHistoryRow>[];
  if (access.canManageLiveStreams ||
      access.canManageVoiceRooms ||
      access.canModerate) {
    try {
      streamHistory = await remote.fetchUserStreamHistory(userId);
      roomHistory = await remote.fetchUserRoomHistory(userId);
    } catch (_) {
      warnings.add('Yayın/oda geçmişi yüklenemedi');
    }
  }

  AdminLiveTellerSummary? teller;
  if (access.canManagePayments || access.isFounder) {
    try {
      teller = await remote.findLiveTellerForUser(userId);
    } catch (_) {}
  }

  var pendingPayments = const <Map<String, dynamic>>[];
  if (access.canManagePayments) {
    try {
      pendingPayments = await remote.fetchPendingPaymentsForUser(userId);
    } catch (_) {}
  }

  var pkBanned = false;
  if (access.canModerate || access.canManageUsers) {
    try {
      final dio = ref.watch(dioProvider);
      final res = await dio.safeGet<dynamic>(ApiEndpoints.pkAdminBans);
      dynamic raw = res.data;
      if (raw is Map) {
        raw = asJsonMap(raw)['bans'] ?? asJsonMap(raw)['items'];
      }
      if (raw is List) {
        pkBanned = raw.any((e) {
          if (e is! Map) return false;
          final m = asJsonMap(e);
          final uid = pick(m, ['userId', 'uid'])?.toString();
          return uid == userId;
        });
      }
    } catch (_) {}
  }

  Map<String, String?> animationSlots = {};
  if (access.canManageSiteAnimations) {
    try {
      final animDs = ref.read(adminSiteAnimationRemoteProvider);
      final map = await animDs.fetchUserAssignments(userId);
      animationSlots = map.map((k, v) => MapEntry(k.name, v));
    } catch (_) {}
  }

  return AdminUserBundle(
    detail: enrichedDetail,
    financeHistory: finance,
    activities: activities,
    giftCollection: collection,
    giftAlbum: album,
    giftLedger: giftLedger,
    streamHistory: streamHistory,
    roomHistory: roomHistory,
    liveTeller: teller,
    pendingPayments: pendingPayments,
    pkBanned: pkBanned,
    siteAnimationSlots: animationSlots,
    loadWarnings: warnings,
  );
});
