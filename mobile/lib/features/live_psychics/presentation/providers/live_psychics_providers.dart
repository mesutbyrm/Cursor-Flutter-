import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/live_fortune_session_manager.dart';
import '../../data/repositories/live_psychics_remote_datasource.dart';
import '../../data/repositories/live_psychics_repository_impl.dart';
import '../../data/services/fortune_teller_profile_resolver.dart';
import '../../data/services/psychic_incoming_sse_service.dart';
import '../../data/services/psychic_room_sse_service.dart';
import '../../domain/entities/psychic_entity.dart';
import '../../domain/repositories/live_psychics_repository.dart';

/// Ana sayfa — çevrimiçi falcılar (bootstrap + section paylaşımlı cache).
final homeOnlinePsychicsProvider =
    FutureProvider<List<PsychicEntity>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(livePsychicsRepositoryProvider);
  final all = await repo.fetchPsychics(page: 1, limit: 20, onlineOnly: true);
  final online = all.where((p) => p.isOnline && p.id.isNotEmpty).toList();
  if (online.isNotEmpty) return online;
  // API online=true ile döndüyse isOnline alanı eksik olabilir.
  if (all.isNotEmpty) return all.where((p) => p.id.isNotEmpty).toList();
  return const [];
});

final livePsychicsRemoteProvider = Provider<LivePsychicsRemoteDataSource>((ref) {
  return LivePsychicsRemoteDataSource(ref.watch(dioProvider));
});

final fortuneTellerProfileResolverProvider =
    Provider<FortuneTellerProfileResolver>((ref) {
  return FortuneTellerProfileResolver(
    ref.watch(dioProvider),
    ref.watch(livePsychicsRemoteProvider),
  );
});

final livePsychicsRepositoryProvider = Provider<LivePsychicsRepository>((ref) {
  return LivePsychicsRepositoryImpl(ref.watch(livePsychicsRemoteProvider));
});

final psychicIncomingSseServiceProvider = Provider<PsychicIncomingSseService>((ref) {
  final service = PsychicIncomingSseService();
  ref.onDispose(service.disconnect);
  return service;
});

final psychicRoomSseServiceProvider = Provider<PsychicRoomSseService>((ref) {
  final service = PsychicRoomSseService();
  ref.onDispose(service.disconnect);
  return service;
});

/// Live Fortune Session Manager — SSE stream + polling fallback.
final liveFortuneSessionManagerProvider = Provider<LiveFortuneSessionManager>((ref) {
  // Adapter: wrap remote datasource to provide needed methods
  final adapter = _LiveSessionRepositoryAdapter(ref.watch(livePsychicsRemoteProvider));
  final manager = LiveFortuneSessionManager(adapter);
  ref.onDispose(manager.dispose);
  return manager;
});

/// Adapter for LiveSessionRepository interface.
class _LiveSessionRepositoryAdapter implements LiveSessionRepository {
  _LiveSessionRepositoryAdapter(this._remote);
  final LivePsychicsRemoteDataSource _remote;

  @override
  Future<String> createSession({
    required String tellerId,
    required String fortuneType,
    required int maxMinutes,
  }) async {
    final result = await _remote.createSession(
      tellerId: tellerId,
      fortuneType: fortuneType,
      durationMinutes: maxMinutes,
    );
    return result?.sessionId ?? '';
  }

  @override
  Future<void> updateSessionStatus({
    required String sessionId,
    required String action,
  }) async {
    await _remote.respondSession(sessionId, action: action);
  }

  @override
  Stream<Map<String, dynamic>> getSessionStream() {
    // Return empty stream for now — PsychicIncomingSseService handles this
    return Stream.empty();
  }

  @override
  Future<List<Map<String, dynamic>>> getIncomingSessions() async {
    try {
      final requests = await _remote.fetchIncomingRequests();
      return requests.map((req) {
        return {
          'id': req.sessionId,
          'sessionId': req.sessionId,
          'tellerId': req.tellerId,
          'fortuneType': 'general',
          'clientId': req.clientId,
        };
      }).toList();
    } catch (_) {
      return const [];
    }
  }
}

/// Interface for session repository.
abstract class LiveSessionRepository {
  Future<String> createSession({
    required String tellerId,
    required String fortuneType,
    required int maxMinutes,
  });

  Future<void> updateSessionStatus({
    required String sessionId,
    required String action,
  });

  Stream<Map<String, dynamic>> getSessionStream();

  Future<List<Map<String, dynamic>>> getIncomingSessions();
}
