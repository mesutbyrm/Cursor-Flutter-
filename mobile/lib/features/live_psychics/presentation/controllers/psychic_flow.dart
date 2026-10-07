import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/auth_route_paths.dart';
import '../../../../core/diagnostics/cf_diag.dart';
import '../../../../core/diagnostics/cf_trace.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/psychic_event_log.dart';
import '../../domain/psychic_client_session_guard.dart';
import '../../data/services/psychic_session_store.dart';
import '../../domain/entities/psychic_entity.dart';
import '../../domain/entities/psychic_session_entity.dart';
import '../../domain/repositories/live_psychics_repository.dart';
import '../providers/live_psychics_providers.dart';
import '../providers/psychic_booking_feedback_provider.dart';

/// Canlı fal navigasyon akışı.
abstract final class PsychicFlow {
  static bool _isInPsychicFlow(String path) {
    if (!path.contains('/canli-falcilar')) return false;
    return path.contains('/waiting') ||
        path.contains('/ad-transition') ||
        path.contains('/session');
  }

  /// Aynı anda tek rezervasyon isteği (profil, hızlı seans ve yayın
  /// ekranındaki çağrıların hepsi bu kapıdan geçer): çift dokunuş veya başka
  /// falcıya geçiş ikinci bir istek göndermez.
  static String? _bookingTellerId;
  static DateTime? _bookingStartedAt;

  /// Takılı kalmış bir isteğin kapıyı sonsuza dek kilitlememesi için üst sınır.
  static const _bookingGateMaxAge = Duration(seconds: 60);

  static bool get isBookingInFlight {
    final started = _bookingStartedAt;
    if (_bookingTellerId == null || started == null) return false;
    return DateTime.now().difference(started) < _bookingGateMaxAge;
  }

  static Future<PsychicSessionEntity?> bookAndOpenWaiting({
    required WidgetRef ref,
    required GoRouter router,
    required PsychicEntity psychic,
    required int durationMinutes,
    required int totalJeton,
    String? fortuneType,
    bool staffExempt = false,
    bool preferVideo = false,
  }) async {
    // `ref`, widget kapandıktan sonra kullanılamaz (StateError). İstek ekran
    // kapandıktan sonra da sürebildiğinden gereken her şey await'lerden ÖNCE
    // alınır.
    final repo = ref.read(livePsychicsRepositoryProvider);
    final feedback = ref.read(psychicBookingFeedbackProvider.notifier);

    if (isBookingInFlight) {
      CfDiag.record(
        CfCategory.fortune,
        'FORTUNE_REQUEST ignored: already in flight',
        level: CfLevel.warn,
        data: {'tellerId': psychic.id, 'activeTellerId': _bookingTellerId},
      );
      _setFeedback(
        feedback,
        'İsteğiniz işleniyor, lütfen bekleyin.',
      );
      return null;
    }
    _bookingTellerId = psychic.id;
    _bookingStartedAt = DateTime.now();

    final trace = CfTrace.start('FORTUNE_REQUEST', CfCategory.fortune);
    trace.step('validation');
    String? outcome;
    try {
      final result = await _bookImpl(
        repo: repo,
        feedback: feedback,
        router: router,
        psychic: psychic,
        durationMinutes: durationMinutes,
        totalJeton: totalJeton,
        fortuneType: fortuneType,
        preferVideo: preferVideo,
        trace: trace,
      );
      outcome = result == null ? 'no-session' : 'ok';
      return result;
    } catch (e, st) {
      outcome = 'error';
      CfDiag.recordError(e, st,
          category: CfCategory.fortune, traceId: trace.traceId);
      _setFeedback(feedback, ApiException.userMessage(e));
      return null;
    } finally {
      _bookingTellerId = null;
      _bookingStartedAt = null;
      trace.finish(outcome: outcome);
    }
  }

  /// Bildirim sağlayıcısı kapanmış olabilir; hata yutulur, akış bozulmaz.
  static void _setFeedback(
    StateController<String?> feedback,
    String message,
  ) {
    try {
      feedback.state = message;
    } catch (err, st) {
      CfDiag.swallowed(err, st, CfCategory.fortune, 'psychic_flow:112');
    }
  }

  static Future<PsychicSessionEntity?> _bookImpl({
    required LivePsychicsRepository repo,
    required StateController<String?> feedback,
    required GoRouter router,
    required PsychicEntity psychic,
    required int durationMinutes,
    required int totalJeton,
    required String? fortuneType,
    required bool preferVideo,
    required CfTrace trace,
  }) async {
    // Sunucu yanıtı gelmezse ekran sonsuza dek bekleyip donmasın: 12 sn sonra
    // «kontrol edilemedi» olarak ele alınır.
    final blocking = await trace.timed(
      'blocking-session lookup',
      () => _findBlockingSession(repo: repo).timeout(
        const Duration(seconds: 12),
        onTimeout: () => (session: null, lookupFailed: true),
      ),
    );
    if (blocking.lookupFailed) {
      // Ağ/sunucu hatası: mevcut seans kontrol edilemedi — çift rezervasyon
      // riskine girmeden kullanıcıya bildir.
      _setFeedback(
        feedback,
        'Bağlantı zaman aşımına uğradı veya mevcut seans kontrol edilemedi. '
        'Tekrar deneyin.',
      );
      return null;
    }
    final existing = blocking.session;
    if (existing != null) {
      final stored = await PsychicSessionStore.load();
      final existingTellerId =
          existing.tellerProfileId?.trim() ?? stored?.psychic.id ?? '';
      final sameTeller = existingTellerId == psychic.id;
      _setFeedback(
        feedback,
        sameTeller
            ? 'Bu falcı ile zaten bekleyen veya aktif bir seansınız var.'
            : 'Başka bir canlı fal seansınız devam ediyor. Önce onu tamamlayın.',
      );

      final tellerPsychic = sameTeller
          ? psychic
          : (existingTellerId.isNotEmpty
                  ? await repo.fetchPsychic(existingTellerId)
                  : null) ??
              stored?.psychic ??
              psychic;

      if (existing.status.isActive) {
        final session =
            await _sessionFromStatus(repo, existing, tellerPsychic);
        if (session != null) {
          router.push(
            '/canli-falcilar/${tellerPsychic.id}/session',
            extra: session,
          );
          return session;
        }
      } else if (existing.status.isWaiting) {
        if (stored != null && stored.sessionId == existing.sessionId) {
          final waitingSession = stored.psychic.id == tellerPsychic.id
              ? stored
              : stored.copyWith(psychic: tellerPsychic);
          router.push(
            '/canli-falcilar/${tellerPsychic.id}/waiting',
            extra: waitingSession,
          );
          return waitingSession;
        }
        final session = await _sessionFromStatus(repo, existing, tellerPsychic);
        if (session != null) {
          await PsychicSessionStore.save(session);
          router.push(
            '/canli-falcilar/${tellerPsychic.id}/waiting',
            extra: session,
          );
          return session;
        }
      }
      return null;
    }

    final type = fortuneType ??
        (psychic.specialties.isNotEmpty ? psychic.specialties.first : 'general');
    PsychicSessionCreateResult? created;
    try {
      created = await trace.timed(
        'API createSession',
        () => repo
            .createSession(
              tellerId: psychic.id,
              durationMinutes: durationMinutes,
              fortuneType: type,
            )
            .timeout(const Duration(seconds: 25)),
      );
    } on TimeoutException {
      _setFeedback(
        feedback,
        'Bağlantı zaman aşımına uğradı. Tekrar deneyin.',
      );
      return null;
    } catch (e) {
      _setFeedback(feedback, ApiException.userMessage(e));
      return null;
    }
    if (created == null) {
      _setFeedback(feedback, 'Seans oluşturulamadı. Lütfen tekrar deneyin.');
      return null;
    }
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
      preferVideo: preferVideo,
    );
    PsychicEventLog.requestSend(
      sessionId: created.sessionId,
      tellerId: psychic.id,
    );
    PsychicEventLog.sessionCreate(
      sessionId: created.sessionId,
      roomId: created.trtcRoomId,
    );
    await trace.timed('session store save', () => PsychicSessionStore.save(session));
    router.push('/canli-falcilar/${psychic.id}/waiting', extra: session);
    trace.step('navigate waiting');
    return session;
  }

  static Future<({PsychicSessionStatusResult? session, bool lookupFailed})>
      _findBlockingSession({
    required LivePsychicsRepository repo,
  }) async {
    final stored = await PsychicSessionStore.load();
    final activeFuture = repo.fetchActiveSessionsOrNull();
    final storedStatusFuture = stored != null && stored.isClient
        ? repo.fetchSessionStatusLookup(stored.sessionId)
        : Future<PsychicStatusLookup>.value(
            const PsychicStatusLookup.notFound(),
          );

    final active = await activeFuture;
    final storedLookup = await storedStatusFuture;
    if (active != null) {
      final fromActive =
          PsychicClientSessionGuard.firstBlockingFromActive(active);
      if (fromActive != null) return (session: fromActive, lookupFailed: false);
    }
    final status = storedLookup.status;
    if (status != null &&
        PsychicClientSessionGuard.blocksNewBooking(status.status)) {
      return (session: status, lookupFailed: false);
    }
    // Hiçbir yerde engel bulunamadı: yalnız sorgular gerçekten başarılıysa
    // «engel yok» say.
    final failed = active == null || storedLookup.isFailed;
    return (session: null, lookupFailed: failed);
  }

  static Future<PsychicSessionEntity?> _sessionFromStatus(
    LivePsychicsRepository repo,
    PsychicSessionStatusResult status,
    PsychicEntity psychic,
  ) async {
    final room = await repo.fetchRoom(status.sessionId);
    final stored = await PsychicSessionStore.load();
    final minutes = status.durationMinutes ?? stored?.durationMinutes ?? 10;
    return PsychicSessionEntity(
      sessionId: status.sessionId,
      psychic: psychic,
      durationMinutes: minutes,
      // Eskiden dakika fiyatı toplam diye yazılıyordu.
      totalJeton: status.totalJeton ??
          (stored?.sessionId == status.sessionId ? stored?.totalJeton : null) ??
          psychic.pricePerMinute * minutes,
      tellerUserId: status.tellerUserId ?? room?.tellerUserId,
      clientId: room?.clientId,
      isClient: true,
      trtcRoomIdOverride: status.trtcRoomId ?? room?.roomId,
      fortuneType: stored?.sessionId == status.sessionId
          ? stored!.fortuneType
          : 'general',
    );
  }

  /// Uygulama açılışında aktif seans veya bekleme ekranına dönüş (PDF §8).
  static Future<void> resumeActiveClientSessions({
    required GoRouter router,
    required LivePsychicsRepository repo,
  }) async {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (_isInPsychicFlow(path) || AuthRoutePaths.isPublicAuthPath(path)) return;

    final active = await repo.fetchActiveSessionsOrNull();
    for (final s in active ?? const <PsychicSessionStatusResult>[]) {
      if (!s.isClient || !s.status.isActive) continue;
      await _openActiveSession(router, repo, s);
      return;
    }

    final stored = await PsychicSessionStore.load();
    if (stored == null || !stored.isClient) return;

    final lookup = await repo.fetchSessionStatusLookup(stored.sessionId);
    // Ağ/sunucu hatasında kayıtlı seansı SİLME — sonraki açılışta devam eder.
    if (lookup.isFailed) return;
    final status = lookup.status;
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
    if (!status.status.isActive || !status.isClient) return;

    PsychicEntity? psychic;
    final tid = tellerId?.trim() ?? status.tellerProfileId ?? '';
    if (tid.isNotEmpty) psychic = await repo.fetchPsychic(tid);
    psychic ??= PsychicEntity(
      id: tid.isNotEmpty ? tid : 'teller',
      name: 'Falcı',
      isOnline: true,
    );
    final room = await repo.fetchRoom(sessionId);
    final session = PsychicSessionEntity(
      sessionId: sessionId,
      psychic: psychic,
      durationMinutes: status.durationMinutes ?? 10,
      totalJeton: status.totalJeton ?? 0,
      tellerUserId: status.tellerUserId ?? room?.tellerUserId,
      clientId: room?.clientId,
      isClient: true,
      trtcRoomIdOverride: status.trtcRoomId ?? room?.roomId,
    );
    await PsychicSessionStore.save(session);

    final path = router.routerDelegate.currentConfiguration.uri.path;
    final adRoute = '/canli-falcilar/${psychic.id}/ad-transition';

    if (path.contains('/session') && path.contains('/canli-falcilar')) {
      return;
    }
    if (path.contains('/ad-transition')) {
      return;
    }
    if (path.contains('/waiting')) {
      router.pushReplacement(adRoute, extra: session);
      return;
    }
    router.push(adRoute, extra: session);
  }

  /// Falcı push bildiriminden kabul sonrası görüşme ekranına git.
  static Future<void> openTellerSessionFromPush({
    required GoRouter router,
    required LivePsychicsRepository repo,
    required String sessionId,
    String? tellerId,
    PsychicEntity? tellerProfile,
    String? roomId,
  }) async {
    final status = await repo.fetchSessionStatus(sessionId);
    if (status == null || status.status.isTerminal) return;
    if (!status.status.isActive) return;

    final tid =
        tellerId?.trim() ?? status.tellerProfileId ?? tellerProfile?.id ?? '';
    PsychicEntity? psychic = tellerProfile;
    if (psychic == null && tid.isNotEmpty) {
      psychic = await repo.fetchPsychic(tid);
    }
    psychic ??= PsychicEntity(
      id: tid.isNotEmpty ? tid : 'teller',
      name: 'Falcı',
      isOnline: true,
    );

    final room = await repo.fetchRoom(sessionId);
    final session = PsychicSessionEntity(
      sessionId: sessionId,
      psychic: psychic,
      durationMinutes: status.durationMinutes ?? room?.maxMinutes ?? 10,
      totalJeton: status.totalJeton ?? 0,
      tellerUserId: status.tellerUserId ?? psychic.userId ?? psychic.trtcUserId,
      clientId: room?.clientId,
      isClient: false,
      trtcRoomIdOverride: roomId ?? status.trtcRoomId ?? room?.roomId ?? sessionId,
      fortuneType: 'general',
    );
    await PsychicSessionStore.save(session);

    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path.contains('/session') && path.contains('/canli-falcilar')) return;

    router.push('/canli-falcilar/${psychic.id}/session', extra: session);
  }
}
