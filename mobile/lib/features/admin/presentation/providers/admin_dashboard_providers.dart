import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_panel_providers.dart';
import 'admin_providers.dart';
import 'staff_access_provider.dart';

/// Admin dashboard — site geneli özet istatistikler.
final adminDashboardStatsProvider =
    FutureProvider.autoDispose<AdminDashboardStats>((ref) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.hasFullAdminDashboard && !access.canManagePayments) {
    return const AdminDashboardStats();
  }

  final remote = ref.watch(adminRemoteProvider);
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> activities = const [];
  var pendingPayments = 0;
  var pendingWithdrawals = 0;

  try {
    stats = await remote.fetchDashboardStats();
  } catch (_) {}
  try {
    activities = await remote.fetchActivities(limit: 50);
  } catch (_) {}
  try {
    final rows = await ref.read(adminPaymentRequestsProvider.future);
    pendingPayments = rows.length;
  } catch (_) {}
  try {
    pendingWithdrawals = await remote.pendingWithdrawalsCount();
  } catch (_) {}

  return AdminDashboardStats.fromMaps(
    stats: stats,
    activities: activities,
    pendingPayments: pendingPayments,
    pendingWithdrawals: pendingWithdrawals,
  );
});

class AdminDashboardStats {
  const AdminDashboardStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.onlineUsers = 0,
    this.totalJeton = 0,
    this.totalCfc = 0,
    this.activeVoiceRooms = 0,
    this.activeLiveStreams = 0,
    this.pendingPayments = 0,
    this.pendingWithdrawals = 0,
    this.unreadNotifications = 0,
  });

  final int totalUsers;
  final int activeUsers;
  final int onlineUsers;
  final int totalJeton;
  final int totalCfc;
  final int activeVoiceRooms;
  final int activeLiveStreams;
  final int pendingPayments;
  final int pendingWithdrawals;
  final int unreadNotifications;

  factory AdminDashboardStats.fromMaps({
    required Map<String, dynamic> stats,
    required List<Map<String, dynamic>> activities,
    required int pendingPayments,
    required int pendingWithdrawals,
  }) {
    int read(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is num) return v.toInt();
        if (v is String) {
          final n = int.tryParse(v);
          if (n != null) return n;
        }
      }
      return 0;
    }

    var online = read(stats, ['onlineUsers', 'online', 'usersOnline']);
    if (online <= 0) {
      online = activities
          .where((a) =>
              a['activityType']?.toString().contains('online') == true)
          .length;
    }

    return AdminDashboardStats(
      totalUsers: read(stats, [
        'totalUsers',
        'usersTotal',
        'userCount',
        'totalMembers',
      ]),
      activeUsers: read(stats, [
        'activeUsers',
        'activeToday',
        'usersActive',
      ]),
      onlineUsers: online,
      totalJeton: read(stats, [
        'totalJeton',
        'jetonTotal',
        'totalJetonBalance',
      ]),
      totalCfc: read(stats, [
        'totalCfc',
        'cfcTotal',
        'totalCfcBalance',
      ]),
      activeVoiceRooms: read(stats, [
        'activeVoiceRooms',
        'activeRooms',
        'chatRoomsActive',
      ]),
      activeLiveStreams: read(stats, [
        'activeLiveStreams',
        'activeStreams',
        'liveStreamsActive',
        'onLive',
      ]),
      pendingPayments: pendingPayments,
      pendingWithdrawals: pendingWithdrawals,
    );
  }
}
