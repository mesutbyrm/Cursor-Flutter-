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

  // Adım 5 (2026-09-24): Secondary data'yı parallelleştir — access kontrolleri hepsi yapıldı.
  final financesFuture = access.canManagePayments
      ? remote
          .fetchUserFinanceHistory(userId: userId, limit: 80)
          .catchError((_) {
            warnings.add('Finans geçmişi yüklenemedi');
            return const [];
          })
      : Future.value(const []);

  // Adım 8 (2026-09-24): Waste reduction — 120 → 50 (sadece 40 kullanılıyor).
  final activitiesFuture = remote
      .fetchActivities(limit: 50)
      .then((all) => all
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
          .take(40)
          .toList(growable: false))
      .catchError((_) {
        warnings.add('Aktivite akışı yüklenemedi');
        return const [];
      });

  final giftsFuture = Future.wait([
    gifts.fetchCollection(userId).catchError((_) => null),
    gifts.fetchAlbum(userId).catchError((_) => null),
  ]).catchError((_) {
    warnings.add('Hediye koleksiyonu yüklenemedi');
    return [null, null];
  });

  final giftLedgerFuture = (access.canManagePayments ||
          access.canModerate ||
          access.canManageGifts)
      ? remote
          .fetchUserGiftLedger(userId)
          .catchError((_) {
            warnings.add('Hediye defteri yüklenemedi');
            return const [];
          })
      : Future.value(const []);

  final streamRoomFuture = (access.canManageLiveStreams ||
          access.canManageVoiceRooms ||
          access.canModerate)
      ? Future.wait([
          remote.fetchUserStreamHistory(userId).catchError((_) => const []),
          remote.fetchUserRoomHistory(userId).catchError((_) => const []),
        ]).catchError((_) {
          warnings.add('Yayın/oda geçmişi yüklenemedi');
          return [const [], const []];
        })
      : Future.value([const [], const []]);

  final tellerFuture = (access.canManagePayments || access.isFounder)
      ? remote.findLiveTellerForUser(userId).catchError((_) => null)
      : Future.value(null);

  final paymentsFuture = access.canManagePayments
      ? remote
          .fetchPendingPaymentsForUser(userId)
          .catchError((_) => const [])
      : Future.value(const []);

  final pkBansFuture = (access.canModerate || access.canManageUsers)
      ? dio
          .safeGet<dynamic>(ApiEndpoints.pkAdminBans)
          .then((res) {
            dynamic raw = res.data;
            if (raw is Map) {
              raw = asJsonMap(raw)['bans'] ?? asJsonMap(raw)['items'];
            }
            return raw is List ? raw : [];
          })
          .catchError((_) => [])
      : Future.value([]);

  final animationFuture = access.canManageSiteAnimations
      ? ref
          .read(adminSiteAnimationRemoteProvider)
          .fetchUserAssignments(userId)
          .catchError((_) => {})
      : Future.value({});

  // Tüm secondary loads paralel çalış.
  final results = await Future.wait([
    financesFuture,
    activitiesFuture,
    giftsFuture,
    giftLedgerFuture,
    streamRoomFuture,
    tellerFuture,
    paymentsFuture,
    pkBansFuture,
    animationFuture,
  ]);

  final finance = results[0] as List<Map<String, dynamic>>;
  final activities = results[1] as List<Map<String, dynamic>>;
  final giftResults = results[2] as List;
  final collection = giftResults[0] as GiftCollection?;
  final album = giftResults[1] as GiftAlbum?;
  final giftLedger = results[3] as List<AdminGiftLedgerRow>;
  final streamRoomResults = results[4] as List;
  final streamHistory = streamRoomResults[0] as List<AdminBroadcastHistoryRow>;
  final roomHistory = streamRoomResults[1] as List<AdminBroadcastHistoryRow>;
  final teller = results[5] as AdminLiveTellerSummary?;
  final pendingPayments = results[6] as List<Map<String, dynamic>>;

  final pkBansList = results[7] as List;
  var pkBanned = false;
  if (pkBansList.isNotEmpty) {
    pkBanned = pkBansList.any((e) {
      if (e is! Map) return false;
      final m = asJsonMap(e);
      final uid = pick(m, ['userId', 'uid'])?.toString();
      return uid == userId;
    });
  }

  final animationMap = results[8] as Map;
  final animationSlots = animationMap.isEmpty
      ? <String, String?>{}
      : animationMap.map((k, v) => MapEntry((k as dynamic).name as String, v as String?));

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
