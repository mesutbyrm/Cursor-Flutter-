import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/agora/domain/entities/agora_credentials.dart';
import '../../features/agora/presentation/providers/agora_providers.dart';
import '../../features/live/domain/entities/live_stream_entity.dart';
import '../../features/live/presentation/providers/live_providers.dart';
import '../providers/auth_selectors.dart';
import 'network_perf.dart';

/// Canlı yayın girişi — ilk kare ASAP; Agora/REST arka planda hazırlanır.
abstract final class LiveEntryPerf {
  static const firstFrameBudget = Duration(seconds: 2);
  static const agoraCacheTtl = Duration(minutes: 3);

  static final Map<String, _AgoraCacheEntry> _agoraCache = {};

  /// Liste dokunuşu — navigasyondan hemen önce.
  static void prewarmOnStreamTap(WidgetRef ref, LiveStreamEntity stream) {
    if (!stream.isLive) return;
    final streamId = stream.id.trim();
    if (streamId.isEmpty) return;
    unawaited(_prefetchAgora(ref, streamId, 'audience'));
    unawaited(_prefetchJoin(ref, streamId));
  }

  static AgoraCredentials? takeAgora({
    required String userId,
    required String streamId,
  }) {
    final key = _cacheKey(userId, streamId);
    final entry = _agoraCache.remove(key);
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > agoraCacheTtl) return null;
    return entry.cred;
  }

  @visibleForTesting
  static void testPutAgora({
    required String userId,
    required String streamId,
    required AgoraCredentials cred,
  }) {
    _agoraCache[_cacheKey(userId, streamId)] =
        _AgoraCacheEntry(cred, DateTime.now());
  }

  static String _cacheKey(String userId, String streamId) =>
      '${userId.trim()}:${streamId.trim()}';

  static Future<void> _prefetchAgora(
    WidgetRef ref,
    String streamId,
    String role,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) return;

    final key = _cacheKey(userId, streamId);
    final existing = _agoraCache[key];
    if (existing != null &&
        DateTime.now().difference(existing.at) <= agoraCacheTtl) {
      return;
    }

    try {
      final cred = await ref.read(agoraRemoteProvider).fetchToken(
            channelName: streamId,
            role: role,
          );
      _agoraCache[key] = _AgoraCacheEntry(cred, DateTime.now());
    } catch (_) {}
  }

  static Future<void> _prefetchJoin(WidgetRef ref, String streamId) async {
    try {
      await ref.read(liveRemoteProvider).joinVideoStream(streamId);
    } catch (_) {}
  }

  /// Token + join paralel — swipe/oda soğuk yolu.
  static Future<AgoraCredentials> fetchAgoraParallel(
    WidgetRef ref, {
    required String streamId,
    required String role,
    required String userId,
  }) async {
    final cached = takeAgora(userId: userId, streamId: streamId);
    if (cached != null && cached.matchesChannel(streamId)) return cached;

    final results = await NetworkPerf.parallel([
      ref.read(agoraRemoteProvider).fetchToken(
            channelName: streamId,
            role: role,
          ),
      ref.read(liveRemoteProvider).joinVideoStream(streamId),
    ]);
    return results[0] as AgoraCredentials;
  }
}

class _AgoraCacheEntry {
  _AgoraCacheEntry(this.cred, this.at);

  final AgoraCredentials cred;
  final DateTime at;
}
