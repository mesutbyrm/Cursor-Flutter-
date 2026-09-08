import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_remote_datasource.dart';
import 'admin_panel_providers.dart';
import 'admin_providers.dart';
import 'staff_access_provider.dart';
import '../../../live/presentation/providers/live_streams_list_notifier.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';

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
  var unreadNotifications = 0;

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
  try {
    final notifs = await ref.read(adminPaymentNotificationsProvider.future);
    unreadNotifications =
        notifs.where((n) => n['read'] != true).length;
  } catch (_) {}

  var base = AdminDashboardStats.fromMaps(
    stats: stats,
    activities: activities,
    pendingPayments: pendingPayments,
    pendingWithdrawals: pendingWithdrawals,
    unreadNotifications: unreadNotifications,
  );

  var activeVoiceRooms = base.activeVoiceRooms;
  if (activeVoiceRooms <= 0) {
    try {
      final rooms = await ref.read(voiceRoomsListNotifierProvider.future);
      activeVoiceRooms = rooms.length;
    } catch (_) {}
  }

  var activeLiveStreams = base.activeLiveStreams;
  if (activeLiveStreams <= 0) {
    try {
      final streams = await ref.read(liveStreamsListNotifierProvider.future);
      activeLiveStreams = streams.where((s) => s.isLive).length;
    } catch (_) {}
  }

  return base.copyWith(
    activeVoiceRooms: activeVoiceRooms,
    activeLiveStreams: activeLiveStreams,
    unreadNotifications: unreadNotifications,
  );
});

/// Dashboard — son aktiviteler (kaydırıcı).
final adminRecentActivitiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.hasFullAdminDashboard && !access.canManagePayments) {
    return const [];
  }
  try {
    return await ref.watch(adminRemoteProvider).fetchActivities(limit: 12);
  } catch (_) {
    return const [];
  }
});

/// Staff — moderasyon/admin filtreli aktiviteler.
final staffFilteredActivitiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.isStaffMember) return const [];

  try {
    final rows = await ref.watch(adminRemoteProvider).fetchActivities(limit: 40);
    return rows.where((a) {
      final type =
          (a['activityType'] ?? a['type'] ?? '').toString().toLowerCase();
      return type.contains('report') ||
          type.contains('ban') ||
          type.contains('kick') ||
          type.contains('moderation') ||
          type.contains('admin') ||
          type.contains('payment') ||
          type.contains('block');
    }).take(8).toList(growable: false);
  } catch (_) {
    return const [];
  }
});

/// Sesli oda finans denetim kayıtları.
final adminVoiceRoomFinanceAuditProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManagePayments && !access.canManageVoiceRooms) {
    return const [];
  }
  return ref.watch(adminRemoteProvider).fetchVoiceRoomFinanceAudit();
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

  AdminDashboardStats copyWith({
    int? totalUsers,
    int? activeUsers,
    int? onlineUsers,
    int? totalJeton,
    int? totalCfc,
    int? activeVoiceRooms,
    int? activeLiveStreams,
    int? pendingPayments,
    int? pendingWithdrawals,
    int? unreadNotifications,
  }) {
    return AdminDashboardStats(
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      totalJeton: totalJeton ?? this.totalJeton,
      totalCfc: totalCfc ?? this.totalCfc,
      activeVoiceRooms: activeVoiceRooms ?? this.activeVoiceRooms,
      activeLiveStreams: activeLiveStreams ?? this.activeLiveStreams,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      pendingWithdrawals: pendingWithdrawals ?? this.pendingWithdrawals,
      unreadNotifications:
          unreadNotifications ?? this.unreadNotifications,
    );
  }

  factory AdminDashboardStats.fromMaps({
    required Map<String, dynamic> stats,
    required List<Map<String, dynamic>> activities,
    required int pendingPayments,
    required int pendingWithdrawals,
    int unreadNotifications = 0,
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
      unreadNotifications: unreadNotifications,
    );
  }
}
