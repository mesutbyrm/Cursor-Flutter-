import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/admin_remote_datasource.dart';
import 'admin_providers.dart';
import 'staff_access_provider.dart';

final adminRemoteProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.watch(dioProvider));
});

/// Admin panel — özet sayılar (kırmızı rozetler).
final adminPanelBadgeCountsProvider =
    FutureProvider.autoDispose<AdminPanelBadges>((ref) async {
  if (!ref.watch(staffAccessProvider).canManagePayments) {
    return const AdminPanelBadges();
  }

  final remote = ref.watch(adminRemoteProvider);

  int pendingPayments = 0;
  try {
    final rows = await ref
        .read(adminPaymentRequestsProvider.future)
        .timeout(const Duration(seconds: 8));
    pendingPayments = rows.length;
  } catch (_) {}

  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> activities = const [];
  Map<String, dynamic> leaderboards = const {};
  var pendingWithdrawals = 0;

  try {
    stats = await remote.fetchDashboardStats();
  } catch (_) {}
  try {
    activities = await remote.fetchActivities(limit: 80);
  } catch (_) {}
  try {
    leaderboards = await remote.fetchLeaderboards(period: 'today');
  } catch (_) {}
  try {
    pendingWithdrawals = await remote.pendingWithdrawalsCount();
  } catch (_) {}

  final today = DateTime.now();
  bool isToday(String? iso) {
    if (iso == null || iso.isEmpty) return false;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return false;
    final local = dt.toLocal();
    return local.year == today.year &&
        local.month == today.month &&
        local.day == today.day;
  }

  var todayMembers = _readInt(stats, [
    'todayMembers',
    'todaySignups',
    'newMembersToday',
    'registeredToday',
    'usersToday',
  ]);
  var todayJetonBuyers = _readInt(stats, [
    'todayJetonBuyers',
    'jetonPurchasesToday',
    'todayJetonPurchases',
    'jetonBuyersToday',
  ]);
  var todayRoomOpeners = _readInt(stats, [
    'todayRoomOpeners',
    'roomsOpenedToday',
    'chatRoomsToday',
  ]);
  var todayBroadcasters = _readInt(stats, [
    'todayBroadcasters',
    'streamsStartedToday',
    'broadcastsToday',
  ]);

  if (todayMembers <= 0) {
    todayMembers = activities
        .where((a) =>
            isToday(a['createdAt']?.toString()) &&
            (a['activityType']?.toString() == 'signup' ||
                a['activityType']?.toString() == 'register'))
        .length;
  }
  if (todayRoomOpeners <= 0) {
    todayRoomOpeners = activities
        .where((a) =>
            isToday(a['createdAt']?.toString()) &&
            (a['activityType']?.toString().contains('room') == true ||
                a['activityType']?.toString() == 'chat_join'))
        .length;
  }
  if (todayBroadcasters <= 0) {
    todayBroadcasters = activities
        .where((a) =>
            isToday(a['createdAt']?.toString()) &&
            (a['activityType']?.toString() == 'stream_started' ||
                a['activityType']?.toString().contains('broadcast') == true))
        .length;
  }

  final topEarners = _leaderboardCount(leaderboards, 'topEarners');
  final topGiftSenders = _leaderboardCount(leaderboards, 'topGiftSenders');

  return AdminPanelBadges(
    pendingPayments: pendingPayments,
    pendingWithdrawals: pendingWithdrawals,
    todayMembers: todayMembers,
    todayJetonBuyers: todayJetonBuyers,
    todayRoomOpeners: todayRoomOpeners,
    todayBroadcasters: todayBroadcasters,
    topEarners: topEarners,
    topGiftSenders: topGiftSenders,
  );
});

int _readInt(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v is num) return v.toInt();
    if (v is String) {
      final n = int.tryParse(v);
      if (n != null) return n;
    }
  }
  return 0;
}

int _leaderboardCount(Map<String, dynamic> boards, String key) {
  final list = boards[key];
  if (list is List) return list.length;
  return 0;
}

class AdminPanelBadges {
  const AdminPanelBadges({
    this.pendingPayments = 0,
    this.pendingWithdrawals = 0,
    this.todayMembers = 0,
    this.todayJetonBuyers = 0,
    this.todayRoomOpeners = 0,
    this.todayBroadcasters = 0,
    this.topEarners = 0,
    this.topGiftSenders = 0,
  });

  final int pendingPayments;
  final int pendingWithdrawals;
  final int todayMembers;
  final int todayJetonBuyers;
  final int todayRoomOpeners;
  final int todayBroadcasters;
  final int topEarners;
  final int topGiftSenders;
}

/// Harf bazlı admin kullanıcı araması (min 1 karakter).
final adminUserSearchProvider =
    AsyncNotifierProvider.autoDispose<AdminUserSearchNotifier, List<Map<String, dynamic>>>(
  AdminUserSearchNotifier.new,
);

class AdminUserSearchNotifier
    extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  Timer? _debounce;
  String _lastQuery = '';

  @override
  Future<List<Map<String, dynamic>>> build() async => const [];

  void setQuery(String query) {
    _debounce?.cancel();
    final q = query.trim();
    _lastQuery = q;

    if (q.isEmpty) {
      state = const AsyncData([]);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String q) async {
    if (q != _lastQuery) return;
    if (!ref.read(staffAccessProvider).canManagePayments) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(adminRemoteProvider).searchUsers(q);
    });
  }
}
