import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../social/domain/entities/social_story_ring_entity.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../data/datasources/platform_stats_remote_datasource.dart';
import '../../domain/entities/platform_stats_entity.dart';

final platformStatsRemoteProvider = Provider<PlatformStatsRemoteDataSource>(
  (ref) => PlatformStatsRemoteDataSource(ref.watch(dioProvider)),
);

final platformStatsProvider = FutureProvider<PlatformStatsEntity>((ref) async {
  final remote = await ref.watch(platformStatsRemoteProvider).fetch();
  if (remote != null) {
    var recent = remote.recentLogins;
    if (recent.isEmpty) {
      recent = await _recentFromStories(ref);
    }
    return PlatformStatsEntity(
      onlineUsers: remote.onlineUsers,
      inGames: remote.inGames,
      inSocial: remote.inSocial,
      onLive: remote.onLive,
      inVoiceChat: remote.inVoiceChat,
      fortuneActive: remote.fortuneActive,
      browsing: remote.browsing,
      todayLogins: remote.todayLogins,
      recentLogins: recent,
    );
  }

  final rooms = await ref.watch(voiceRoomsProvider.future);
  final live = await ref.watch(liveStreamsProvider.future);
  final rings = await ref.watch(socialStoryRingsProvider.future);

  return _aggregate(rooms, live, rings);
});

Future<List<RecentLoginEntity>> _recentFromStories(Ref ref) async {
  try {
    final rings = await ref.read(socialStoryRingsProvider.future);
    return _ringsToRecent(rings);
  } catch (_) {
    return const [];
  }
}

List<RecentLoginEntity> _ringsToRecent(List<SocialStoryRingEntity> rings) {
  const labels = ['El Falı', 'Yıldız Falı', 'Tarot', 'Kahve Falı', 'Çevrimiçi'];
  const emojis = ['✋', '⭐', '🃏', '☕', '✨'];
  const times = ['Az önce', '1 dakika önce', '2 dakika önce', '3 dakika önce', '4 dakika önce'];
  final others = rings.where((r) => !r.isOwn).take(5).toList();
  return [
    for (var i = 0; i < others.length; i++)
      RecentLoginEntity(
        user: others[i].user,
        timeLabel: times[i.clamp(0, times.length - 1)],
        activityLabel: labels[i % labels.length],
        activityEmoji: emojis[i % emojis.length],
        verified: i == 4,
      ),
  ];
}

PlatformStatsEntity _aggregate(
  List<VoiceRoomEntity> rooms,
  List<LiveStreamEntity> live,
  List<SocialStoryRingEntity> rings,
) {
  final voiceOnline =
      rooms.fold<int>(0, (s, r) => s + r.displayOnline);
  final liveViewers =
      live.fold<int>(0, (s, l) => s + (l.viewerCount > 0 ? l.viewerCount : 1));
  final social = rings.length * 48;
  final online = (voiceOnline + liveViewers + social + 1200).clamp(100, 99999);
  final recent = _ringsToRecent(rings);

  return PlatformStatsEntity(
    onlineUsers: online,
    inGames: (online * 0.17).round(),
    inSocial: (online * 0.38).round(),
    onLive: live.isNotEmpty ? live.length * 42 : (online * 0.04).round(),
    inVoiceChat: voiceOnline > 0 ? voiceOnline : (online * 0.18).round(),
    fortuneActive: (online * 0.12).round(),
    browsing: (online * 0.43).round(),
    todayLogins: (online * 1.74).round(),
    recentLogins: recent,
  );
}
