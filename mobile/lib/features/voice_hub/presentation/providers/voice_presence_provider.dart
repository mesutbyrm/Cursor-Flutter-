import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Geliştirilmiş Presence: Ses seviyesi ve konuşma takibi
class EnhancedPresence {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int? seatIndex;
  final bool isSpeaking;
  final double audioLevel; // 0-1
  final bool micEnabled;
  final DateTime joinedAt;
  final DateTime? lastHeartbeatAt;
  final int speakingDuration; // ms
  final DateTime? lastSpokeAt;

  EnhancedPresence({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.seatIndex,
    this.isSpeaking = false,
    this.audioLevel = 0.0,
    this.micEnabled = false,
    required this.joinedAt,
    this.lastHeartbeatAt,
    this.speakingDuration = 0,
    this.lastSpokeAt,
  });

  factory EnhancedPresence.fromJson(Map<String, dynamic> json) {
    return EnhancedPresence(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      avatarUrl: json['avatarUrl'],
      seatIndex: json['seatIndex'],
      isSpeaking: json['isSpeaking'] ?? false,
      audioLevel: (json['audioLevel'] ?? 0).toDouble(),
      micEnabled: json['micEnabled'] ?? false,
      joinedAt: DateTime.parse(json['joinedAt']),
      lastHeartbeatAt: json['lastHeartbeatAt'] != null
          ? DateTime.parse(json['lastHeartbeatAt'])
          : null,
      speakingDuration: json['speakingDuration'] ?? 0,
      lastSpokeAt: json['lastSpokeAt'] != null
          ? DateTime.parse(json['lastSpokeAt'])
          : null,
    );
  }
}

/// Voice Presence Service: Ses durumu izleme
class VoicePresenceService {
  Future<EnhancedPresence?> updatePresence(String roomId, String userId, {
    bool? isSpeaking,
    double? audioLevel,
    bool? micEnabled,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return EnhancedPresence(
      userId: userId,
      displayName: 'User $userId',
      isSpeaking: isSpeaking ?? false,
      audioLevel: audioLevel ?? 0.0,
      micEnabled: micEnabled ?? false,
      joinedAt: DateTime.now(),
    );
  }

  Future<List<EnhancedPresence>> getRoomPresence(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  Future<void> heartbeat(String roomId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<Map<String, dynamic>> getRoomPresenceStats(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'totalUsers': 0,
      'speakingUsers': 0,
      'avgAudioLevel': 0.0,
      'activeMics': 0,
    };
  }
}

final voicePresenceServiceProvider = Provider((ref) => VoicePresenceService());

/// Room presence list
final roomPresenceProvider = FutureProvider.family<List<EnhancedPresence>, String>((ref, roomId) async {
  final service = ref.watch(voicePresenceServiceProvider);
  return service.getRoomPresence(roomId);
});

/// Room presence statistics
final roomPresenceStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, roomId) async {
  final service = ref.watch(voicePresenceServiceProvider);
  return service.getRoomPresenceStats(roomId);
});

/// Presence update notifier
class UpdatePresenceNotifier extends StateNotifier<AsyncValue<EnhancedPresence?>> {
  UpdatePresenceNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> update(String roomId, String userId, {
    bool? isSpeaking,
    double? audioLevel,
    bool? micEnabled,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(voicePresenceServiceProvider);
      final presence = await service.updatePresence(
        roomId,
        userId,
        isSpeaking: isSpeaking,
        audioLevel: audioLevel,
        micEnabled: micEnabled,
      );
      state = AsyncValue.data(presence);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendHeartbeat(String roomId, String userId) async {
    try {
      final service = ref.read(voicePresenceServiceProvider);
      await service.heartbeat(roomId, userId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final updatePresenceNotifierProvider = StateNotifierProvider<UpdatePresenceNotifier, AsyncValue<EnhancedPresence?>>((ref) {
  return UpdatePresenceNotifier(ref);
});

/// Real-time presence state - speaking users
final speakingUsersProvider = Provider.family<List<String>, String>((ref, roomId) {
  final presenceAsync = ref.watch(roomPresenceProvider(roomId));
  return presenceAsync.maybeWhen(
    data: (presence) => presence.where((p) => p.isSpeaking).map((p) => p.userId).toList(),
    orElse: () => [],
  );
});

/// Mic-enabled users
final micEnabledUsersProvider = Provider.family<List<String>, String>((ref, roomId) {
  final presenceAsync = ref.watch(roomPresenceProvider(roomId));
  return presenceAsync.maybeWhen(
    data: (presence) => presence.where((p) => p.micEnabled).map((p) => p.userId).toList(),
    orElse: () => [],
  );
});

/// Average audio level in room
final roomAudioLevelProvider = Provider.family<double, String>((ref, roomId) {
  final presenceAsync = ref.watch(roomPresenceProvider(roomId));
  return presenceAsync.maybeWhen(
    data: (presence) {
      if (presence.isEmpty) return 0.0;
      final total = presence.fold<double>(0, (sum, p) => sum + p.audioLevel);
      return total / presence.length;
    },
    orElse: () => 0.0,
  );
});
