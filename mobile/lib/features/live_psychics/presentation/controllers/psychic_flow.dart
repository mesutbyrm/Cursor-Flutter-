import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/auth_route_paths.dart';
import '../../data/services/psychic_session_store.dart';
import '../../domain/entities/psychic_entity.dart';
import '../../domain/entities/psychic_session_entity.dart';
import '../../domain/repositories/live_psychics_repository.dart';
import '../providers/live_psychics_providers.dart';

/// Canlı fal navigasyon akışı.
abstract final class PsychicFlow {
  static bool _isInPsychicFlow(String path) {
    if (!path.contains('/canli-falcilar')) return false;
    return path.contains('/waiting') ||
        path.contains('/ad-transition') ||
        path.contains('/session');
  }

  static Future<PsychicSessionEntity?> bookAndOpenWaiting({
    required WidgetRef ref,
    required GoRouter router,
    required PsychicEntity psychic,
    required int durationMinutes,
    required int totalJeton,
    String? fortuneType,
  }) async {
    final repo = ref.read(livePsychicsRepositoryProvider);
    final type = fortuneType ??
        (psychic.specialties.isNotEmpty ? psychic.specialties.first : 'general');
    final created = await repo.createSession(
      tellerId: psychic.id,
      tellerUserId: psychic.trtcUserId,
      durationMinutes: durationMinutes,
      fortuneType: type,
    );
    if (created == null) return null;
    final session = PsychicSessionEntity(
      sessionId: created.sessionId,
      psychic: psychic,
      durationMinutes: created.maxMinutes ?? durationMinutes,
      totalJeton: created.creditsCharged ?? totalJeton,
      tellerUserId: created.tellerUserId ?? psychic.trtcUserId,
      clientId: created.clientId,
      isClient: true,
      trtcRoomIdOverride: created.trtcRoomId,
      fortuneType: type,
    );
    await PsychicSessionStore.save(session);
    router.push('/canli-falcilar/${psychic.id}/waiting', extra: session);
    return session;
  }

  /// Uygulama açılışında aktif seans veya bekleme ekranına dönüş (PDF §8).
  static Future<void> resumeActiveClientSessions({
    required GoRouter router,
    required LivePsychicsRepository repo,
  }) async {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (_isInPsychicFlow(path) || AuthRoutePaths.isPublicAuthPath(path)) return;

    final active = await repo.fetchActiveSessions();
    for (final s in active) {
      if (!s.isClient || !s.status.isActive) continue;
      await _openActiveSession(router, repo, s);
      return;
    }

    final stored = await PsychicSessionStore.load();
    if (stored == null || !stored.isClient) return;

    final status = await repo.fetchSessionStatus(stored.sessionId);
    if (status == null) {
      await PsychicSessionStore.clear();
      return;
    }
    if (status.status.isActive) {
      await _openActiveSession(router, repo, status, stored: stored);
    } else if (status.status.isWaiting) {
      router.push('/canli-falcilar/${stored.psychic.id}/waiting', extra: stored);
    } else if (status.status.isTerminal) {
      await PsychicSessionStore.clear();
    }
  }

  static Future<void> _openActiveSession(
    GoRouter router,
    LivePsychicsRepository repo,
    PsychicSessionStatusResult status, {
    PsychicSessionEntity? stored,
  }) async {
    PsychicEntity? psychic;
    final tid = status.tellerProfileId?.trim() ?? stored?.psychic.id ?? '';
    if (tid.isNotEmpty) psychic = await repo.fetchPsychic(tid);
    psychic ??= stored?.psychic ??
        PsychicEntity(
          id: tid.isNotEmpty ? tid : 'teller',
          name: 'Falcı',
          isOnline: true,
        );
    final session = PsychicSessionEntity(
      sessionId: status.sessionId,
      psychic: psychic,
      durationMinutes: status.durationMinutes ?? stored?.durationMinutes ?? 10,
      totalJeton: status.totalJeton ?? stored?.totalJeton ?? 0,
      tellerUserId: status.tellerUserId ?? stored?.tellerUserId,
      clientId: stored?.clientId,
      isClient: true,
      trtcRoomIdOverride: status.trtcRoomId ?? stored?.trtcRoomIdOverride,
      fortuneType: stored?.fortuneType ?? 'general',
    );
    await PsychicSessionStore.save(session);
    router.push('/canli-falcilar/${psychic.id}/session', extra: session);
  }

  static Future<void> resumeFromPush({
    required GoRouter router,
    required LivePsychicsRepository repo,
    required String sessionId,
    String? tellerId,
  }) async {
    final status = await repo.fetchSessionStatus(sessionId);
    if (status == null || status.status.isTerminal) return;
    if (!status.status.isActive) return;
    PsychicEntity? psychic;
    final tid = tellerId?.trim() ?? status.tellerProfileId ?? '';
    if (tid.isNotEmpty) psychic = await repo.fetchPsychic(tid);
    psychic ??= PsychicEntity(id: tid.isNotEmpty ? tid : 'teller', name: 'Falcı', isOnline: true);
    final session = PsychicSessionEntity(
      sessionId: sessionId,
      psychic: psychic,
      durationMinutes: status.durationMinutes ?? 10,
      totalJeton: status.totalJeton ?? 0,
      tellerUserId: status.tellerUserId,
      isClient: status.isClient,
      trtcRoomIdOverride: status.trtcRoomId,
    );
    await PsychicSessionStore.save(session);
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path.contains('/canli-falcilar') &&
        (path.contains('/session') ||
            path.contains('/waiting') ||
            path.contains('/ad-transition'))) {
      return;
    }
    if (path.contains('/waiting')) {
      router.pushReplacement('/canli-falcilar/${psychic.id}/ad-transition', extra: session);
    } else {
      router.push('/canli-falcilar/${psychic.id}/session', extra: session);
    }
  }
}
