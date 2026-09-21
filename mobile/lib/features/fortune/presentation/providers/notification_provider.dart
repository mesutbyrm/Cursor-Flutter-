import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_instance.dart';

// Models
class AppNotification {
  final String notificationId;
  final String type;
  final String title;
  final String message;
  final String? icon;
  final String? actionUrl;
  final bool read;
  final DateTime createdAt;
  final DateTime? expiresAt;

  AppNotification({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.message,
    this.icon,
    this.actionUrl,
    required this.read,
    required this.createdAt,
    this.expiresAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notificationId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      icon: json['icon'] as String?,
      actionUrl: json['actionUrl'] as String?,
      read: json['read'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }
}

class NotificationPreference {
  final bool dailyReminderEnabled;
  final String dailyReminderTime;
  final String dailyReminderTimezone;
  final bool streakReminderEnabled;
  final String streakReminderTime;
  final bool achievementsEnabled;
  final bool socialEnabled;
  final bool socialLikesEnabled;
  final bool socialCommentsEnabled;
  final bool socialSharesEnabled;
  final bool featuresEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool inAppEnabled;

  NotificationPreference({
    required this.dailyReminderEnabled,
    required this.dailyReminderTime,
    required this.dailyReminderTimezone,
    required this.streakReminderEnabled,
    required this.streakReminderTime,
    required this.achievementsEnabled,
    required this.socialEnabled,
    required this.socialLikesEnabled,
    required this.socialCommentsEnabled,
    required this.socialSharesEnabled,
    required this.featuresEnabled,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.inAppEnabled,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    final prefs = json['preferences'] as Map<String, dynamic>;
    return NotificationPreference(
      dailyReminderEnabled: (prefs['dailyReminder'] as Map)['enabled'] as bool,
      dailyReminderTime: (prefs['dailyReminder'] as Map)['time'] as String,
      dailyReminderTimezone: (prefs['dailyReminder'] as Map)['timezone'] as String,
      streakReminderEnabled: (prefs['streakReminder'] as Map)['enabled'] as bool,
      streakReminderTime: (prefs['streakReminder'] as Map)['time'] as String,
      achievementsEnabled: (prefs['achievements'] as Map)['enabled'] as bool,
      socialEnabled: (prefs['social'] as Map)['enabled'] as bool,
      socialLikesEnabled: (prefs['social'] as Map)['likes'] as bool,
      socialCommentsEnabled: (prefs['social'] as Map)['comments'] as bool,
      socialSharesEnabled: (prefs['social'] as Map)['shares'] as bool,
      featuresEnabled: (prefs['features'] as Map)['enabled'] as bool,
      quietHoursEnabled: (prefs['quiet_hours'] as Map)['enabled'] as bool,
      quietHoursStart: (prefs['quiet_hours'] as Map)['startTime'] as String,
      quietHoursEnd: (prefs['quiet_hours'] as Map)['endTime'] as String,
      pushEnabled: (prefs['channels'] as Map)['push'] as bool,
      emailEnabled: (prefs['channels'] as Map)['email'] as bool,
      inAppEnabled: (prefs['channels'] as Map)['inApp'] as bool,
    );
  }
}

// Service
class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  Future<List<AppNotification>> getNotifications({
    int limit = 20,
    int offset = 0,
    String type = 'all',
    String filter = 'all',
  }) async {
    final response = await _dio.get('/api/notifications', queryParameters: {
      'limit': limit,
      'offset': offset,
      'type': type,
      'filter': filter,
    });
    return (response.data['data']['notifications'] as List)
        .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationPreference> getPreferences() async {
    final response = await _dio.get('/api/notifications/preferences');
    return NotificationPreference.fromJson(response.data['data']);
  }

  Future<void> updatePreferences(Map<String, dynamic> updates) async {
    await _dio.put('/api/notifications/preferences', data: updates);
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.put('/api/notifications/$notificationId/read', data: {'read': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _dio.delete('/api/notifications/$notificationId');
  }

  Future<void> sendTestNotification() async {
    await _dio.post('/api/notifications/test', data: {
      'type': 'daily_reminder',
      'channel': 'push',
    });
  }
}

// Providers
final notificationServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationService(dio);
});

final notificationsProvider = FutureProvider.family<
  List<AppNotification>,
  ({int limit, int offset, String type, String filter})
>((ref, params) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getNotifications(
    limit: params.limit,
    offset: params.offset,
    type: params.type,
    filter: params.filter,
  );
});

final notificationPreferencesProvider = FutureProvider<NotificationPreference>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getPreferences();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final notifs = await ref.watch(
    notificationsProvider((limit: 100, offset: 0, type: 'all', filter: 'unread')).future,
  );
  return notifs.length;
});

// Update preferences notifier
class UpdatePreferencesNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationService _service;

  UpdatePreferencesNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> updatePreferences(Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.updatePreferences(updates));
  }
}

final updatePreferencesProvider = StateNotifierProvider<UpdatePreferencesNotifier, AsyncValue<void>>(
  (ref) => UpdatePreferencesNotifier(ref.watch(notificationServiceProvider)),
);
