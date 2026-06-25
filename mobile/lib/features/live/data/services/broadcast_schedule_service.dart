import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/push/push_notification_service.dart';

class ScheduledBroadcast {
  const ScheduledBroadcast({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.notified = false,
  });

  factory ScheduledBroadcast.fromJson(Map<String, dynamic> json) {
    return ScheduledBroadcast(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Canlı yayın',
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      notified: json['notified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'notified': notified,
      };

  final String id;
  final String title;
  final DateTime scheduledAt;
  final bool notified;
}

class BroadcastScheduleService {
  BroadcastScheduleService(this._prefs);

  static const _storageKey = 'scheduled_broadcasts_v1';

  final SharedPreferences _prefs;

  static Future<BroadcastScheduleService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return BroadcastScheduleService(prefs);
  }

  List<ScheduledBroadcast> loadAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => ScheduledBroadcast.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<ScheduledBroadcast> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }

  Future<ScheduledBroadcast> schedule({
    required String title,
    required DateTime scheduledAt,
  }) async {
    final item = ScheduledBroadcast(
      id: 'sb-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Canlı yayın' : title.trim(),
      scheduledAt: scheduledAt,
    );
    final all = [...loadAll(), item];
    await saveAll(all);

    final delay = scheduledAt.difference(DateTime.now());
    if (!delay.isNegative && delay <= const Duration(hours: 24)) {
      Future.delayed(delay, () async {
        await PushNotificationService.instance.showLocal(
          id: item.id.hashCode,
          title: 'Yayın zamanı',
          body: item.title,
          payload: '/live/type',
          urgent: true,
        );
      });
    }
    return item;
  }

  Future<void> remove(String id) async {
    final all = loadAll().where((e) => e.id != id).toList();
    await saveAll(all);
  }

  /// Uygulama açıkken yaklaşan planları kontrol et.
  Future<void> checkUpcomingReminders() async {
    final now = DateTime.now();
    var changed = false;
    final all = loadAll();
    final next = <ScheduledBroadcast>[];
    for (final item in all) {
      if (item.notified) {
        next.add(item);
        continue;
      }
      final diff = item.scheduledAt.difference(now);
      if (diff.isNegative) {
        changed = true;
        continue;
      }
      if (diff <= const Duration(minutes: 15)) {
        await PushNotificationService.instance.showLocal(
          id: item.id.hashCode,
          title: 'Yayın yaklaşıyor',
          body: '${item.title} — ${diff.inMinutes} dk sonra',
          payload: '/live/type',
        );
        next.add(ScheduledBroadcast(
          id: item.id,
          title: item.title,
          scheduledAt: item.scheduledAt,
          notified: true,
        ));
        changed = true;
      } else {
        next.add(item);
      }
    }
    if (changed) await saveAll(next);
  }
}
