import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/live_broadcast_session.dart';
import '../domain/entities/live_guest_layout.dart';

/// Yayıncı bağlantısı koptuğunda yayını 5 dk süreyle saklar; devam için.
class HostLiveStreamRecovery {
  HostLiveStreamRecovery._();

  static const _key = 'host_live_stream_recovery_v1';
  static const gracePeriod = Duration(minutes: 5);

  static Future<void> save(LiveBroadcastSession session) async {
    final streamId = session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'streamId': streamId,
        'title': session.title,
        'category': session.category,
        'description': session.description,
        'tags': session.tags,
        'streamerName': session.streamerName,
        'streamerHandle': session.streamerHandle,
        'avatarUrl': session.avatarUrl,
        'backgroundUrl': session.backgroundUrl,
        'coverImageUrl': session.coverImageUrl,
        'hostUserId': session.hostUserId,
        'initialMicOn': session.initialMicOn,
        'initialCameraOn': session.initialCameraOn,
        'guestLayout': session.guestLayout.name,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  static Future<LiveBroadcastSession?> loadIfValid() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(map['savedAt']?.toString() ?? '');
      if (savedAt == null) {
        await clear();
        return null;
      }
      if (DateTime.now().toUtc().difference(savedAt.toUtc()) > gracePeriod) {
        await clear();
        return null;
      }
      final streamId = map['streamId']?.toString();
      if (streamId == null || streamId.isEmpty) return null;
      final layoutName = map['guestLayout']?.toString() ?? 'solo';
      final layout = LiveGuestLayout.values.firstWhere(
        (e) => e.name == layoutName,
        orElse: () => LiveGuestLayout.solo,
      );
      return LiveBroadcastSession.demoHost(
        title: map['title']?.toString() ?? 'Canlı yayın',
        category: map['category']?.toString() ?? 'Sohbet',
        tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        description: map['description']?.toString() ?? '',
        streamerName: map['streamerName']?.toString(),
        streamerHandle: map['streamerHandle']?.toString(),
        avatarUrl: map['avatarUrl']?.toString(),
        backgroundUrl: map['backgroundUrl']?.toString(),
        coverImageUrl: map['coverImageUrl']?.toString(),
      ).copyWith(
        streamId: streamId,
        hostUserId: map['hostUserId']?.toString(),
        initialMicOn: map['initialMicOn'] == true,
        initialCameraOn: map['initialCameraOn'] != false,
        guestLayout: layout,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

}
