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

// Adım 14 (2026-09-24): Granüler sağlayıcılar — her veri tipi bağımsız.

Future<AdminUserDetail> _fetchAdminUserDetail(Ref<dynamic> ref, String userId) async {
  final remote = ref.watch(adminRemoteProvider);
  final dio = ref.watch(dioProvider);

  Map<String, dynamic> admin = {};
  Map<String, dynamic> public = {};
  Map<String, dynamic>? fullProfile;

  try {
    fullProfile = await remote.tryFetchUserFull(userId);
    if (fullProfile != null) {
      admin = {...admin, ...fullProfile};
    }
  } catch (_) {}

  try {
    admin = {...admin, ...await remote.fetchUser(userId)};
  } catch (_) {}

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
  } catch (_) {}

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

  return AdminUserDetail.fromMaps(
    userId: userId,
    admin: {...detail.raw, if (adsWatched > 0) 'adsWatched': adsWatched},
    publicProfile: public,
    stats: fullProfile,
  );
}

final adminUserBasicDetailProvider = FutureProvider.autoDispose
    .family<AdminUserDetail, String>((ref, userId) {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManageUsers &&
      !access.canManagePayments &&
      !access.canModerate) {
    return Future.value(AdminUserDetail.fromMaps(userId: userId));
  }
  return _fetchAdminUserDetail(ref, userId);
});

final adminUserFinanceHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManagePayments) return const [];
  return ref.read(adminRemoteProvider).fetchUserFinanceHistory(userId: userId, limit: 80);
});

// Adım 15 (2026-09-24): Activity pagination — sonsuz scroll desteği.
final adminUserActivityPageSizeProvider =
    StateProvider.autoDispose.family<int, String>((ref, userId) => 40);

final adminUserActivitiesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final pageSize = ref.watch(adminUserActivityPageSizeProvider(userId));
  final all = await ref.read(adminRemoteProvider).fetchActivities(limit: 50);
  final filtered = all
      .where((a) {
        final uid = pick(a, ['userId', 'targetUserId'])?.toString() ?? '';
        if (uid == userId) return true;
        final user = a['user'];
        if (user is Map) {
          final id = pick(asJsonMap(user), ['id', 'userId'])?.toString() ?? '';
          if (id == userId) return true;
        }
        return false;
      })
      .toList(growable: false);
  return filtered.take(pageSize).toList(growable: false);
});

final adminUserActivityHasMoreProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, userId) async {
  final pageSize = ref.watch(adminUserActivityPageSizeProvider(userId));
  final all = await ref.read(adminRemoteProvider).fetchActivities(limit: 50);
  final filtered = all
      .where((a) {
        final uid = pick(a, ['userId', 'targetUserId'])?.toString() ?? '';
        if (uid == userId) return true;
        final user = a['user'];
        if (user is Map) {
          final id = pick(asJsonMap(user), ['id', 'userId'])?.toString() ?? '';
          if (id == userId) return true;
        }
        return false;
      })
      .length;
  return filtered > pageSize;
});

final adminUserGiftCollectionProvider = FutureProvider.autoDispose
    .family<GiftCollection?, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  final gifts = GiftInsightsRemoteDataSource(dio);
  return gifts.fetchCollection(userId);
});

final adminUserGiftAlbumProvider = FutureProvider.autoDispose
    .family<GiftAlbum?, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  final gifts = GiftInsightsRemoteDataSource(dio);
  return gifts.fetchAlbum(userId);
});

final adminUserGiftLedgerProvider = FutureProvider.autoDispose
    .family<List<AdminGiftLedgerRow>, String>((ref, userId) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManagePayments && !access.canModerate && !access.canManageGifts) {
    return const [];
  }
  return ref.read(adminRemoteProvider).fetchUserGiftLedger(userId);
});

final adminUserStreamHistoryProvider = FutureProvider.autoDispose
    .family<List<AdminBroadcastHistoryRow>, String>((ref, userId) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManageLiveStreams && !access.canManageVoiceRooms && !access.canModerate) {
    return const [];
  }
  return ref.read(adminRemoteProvider).fetchUserStreamHistory(userId);
});

final adminUserRoomHistoryProvider = FutureProvider.autoDispose
    .family<List<AdminBroadcastHistoryRow>, String>((ref, userId) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManageLiveStreams && !access.canManageVoiceRooms && !access.canModerate) {
    return const [];
  }
  return ref.read(adminRemoteProvider).fetchUserRoomHistory(userId);
});

final adminUserLiveTellerProvider = FutureProvider.autoDispose
    .family<AdminLiveTellerSummary?, String>((ref, userId) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManagePayments && !access.isFounder) return null;
  return ref.read(adminRemoteProvider).findLiveTellerForUser(userId);
});

final adminUserPendingPaymentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManagePayments) return const [];
  return ref.read(adminRemoteProvider).fetchPendingPaymentsForUser(userId);
});

final adminUserPkBannedProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, userId) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.canModerate && !access.canManageUsers) return false;

  final dio = ref.watch(dioProvider);
  final res = await dio.safeGet<dynamic>(ApiEndpoints.pkAdminBans);
  dynamic raw = res.data;
  if (raw is Map) {
    raw = asJsonMap(raw)['bans'] ?? asJsonMap(raw)['items'];
  }
  final list = raw is List ? raw : [];

  return list.any((e) {
    if (e is! Map) return false;
    final m = asJsonMap(e);
    final uid = pick(m, ['userId', 'uid'])?.toString();
    return uid == userId;
  });
});

final adminUserSiteAnimationSlotsProvider = FutureProvider.autoDispose
    .family<Map<String, String?>, String>((ref, userId) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManageSiteAnimations) return const {};

  final map = await ref
      .read(adminSiteAnimationRemoteProvider)
      .fetchUserAssignments(userId);

  return map.isEmpty
      ? <String, String?>{}
      : map.map((k, v) => MapEntry((k as dynamic).name as String, v));
});

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

  final warnings = <String>[];

  try {
    final [detail, finance, activities, giftData, ledger, streamHistory, roomHistory, teller, payments, pkBanned, animSlots] = await Future.wait([
      ref.read(adminUserBasicDetailProvider(userId).future),
      ref.read(adminUserFinanceHistoryProvider(userId).future).catchError((_) {
        warnings.add('Finans geçmişi yüklenemedi');
        return const [] as List<Map<String, dynamic>>;
      }),
      ref.read(adminUserActivitiesProvider(userId).future).catchError((_) {
        warnings.add('Aktivite akışı yüklenemedi');
        return const [] as List<Map<String, dynamic>>;
      }),
      Future.wait([
        ref.read(adminUserGiftCollectionProvider(userId).future).catchError((_) => null),
        ref.read(adminUserGiftAlbumProvider(userId).future).catchError((_) => null),
      ]).catchError((_) {
        warnings.add('Hediye koleksiyonu yüklenemedi');
        return [null, null];
      }),
      ref.read(adminUserGiftLedgerProvider(userId).future).catchError((_) {
        warnings.add('Hediye defteri yüklenemedi');
        return const [] as List<AdminGiftLedgerRow>;
      }),
      ref.read(adminUserStreamHistoryProvider(userId).future).catchError((_) {
        warnings.add('Yayın/oda geçmişi yüklenemedi');
        return const [] as List<AdminBroadcastHistoryRow>;
      }),
      ref.read(adminUserRoomHistoryProvider(userId).future).catchError((_) {
        warnings.add('Yayın/oda geçmişi yüklenemedi');
        return const [] as List<AdminBroadcastHistoryRow>;
      }),
      ref.read(adminUserLiveTellerProvider(userId).future).catchError((_) => null as AdminLiveTellerSummary?),
      ref.read(adminUserPendingPaymentsProvider(userId).future).catchError((_) {
        warnings.add('Bekleme ödemeleri yüklenemedi');
        return const [] as List<Map<String, dynamic>>;
      }),
      ref.read(adminUserPkBannedProvider(userId).future).catchError((_) => false),
      ref.read(adminUserSiteAnimationSlotsProvider(userId).future).catchError((_) {
        warnings.add('Site animasyonları yüklenemedi');
        return const <String, String?>{};
      }),
    ]);

    final giftList = giftData as List<dynamic>;

    return AdminUserBundle(
      detail: detail as AdminUserDetail,
      financeHistory: finance as List<Map<String, dynamic>>,
      activities: activities as List<Map<String, dynamic>>,
      giftCollection: giftList.isNotEmpty ? giftList[0] as GiftCollection? : null,
      giftAlbum: giftList.length > 1 ? giftList[1] as GiftAlbum? : null,
      giftLedger: ledger as List<AdminGiftLedgerRow>,
      streamHistory: streamHistory as List<AdminBroadcastHistoryRow>,
      roomHistory: roomHistory as List<AdminBroadcastHistoryRow>,
      liveTeller: teller as AdminLiveTellerSummary?,
      pendingPayments: payments as List<Map<String, dynamic>>,
      pkBanned: pkBanned as bool,
      siteAnimationSlots: animSlots as Map<String, String?>,
      loadWarnings: warnings,
    );
  } catch (_) {
    warnings.add('Detay yüklemesi başarısız');
    return AdminUserBundle(
      detail: AdminUserDetail.fromMaps(userId: userId),
      loadWarnings: warnings,
    );
  }
});
