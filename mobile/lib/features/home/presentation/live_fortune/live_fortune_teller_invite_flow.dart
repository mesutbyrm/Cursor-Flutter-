import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../providers/home_providers.dart';
import '../widgets/fortune_request_dialog.dart';
import '../widgets/live_fortune_invite_action.dart';
import '../widgets/live_fortune_session_start_sheet.dart';

/// Falcı davet popup + kabul sonrası seans başlatma akışı (web ile aynı UI).
class LiveFortuneTellerInviteFlow {
  LiveFortuneTellerInviteFlow._();

  static BuildContext? get _navContext => rootNavigatorKey.currentContext;

  static Future<BuildContext?> _waitForNavContext({
    int attempts = 12,
    Duration step = const Duration(milliseconds: 80),
  }) async {
    for (var i = 0; i < attempts; i++) {
      final ctx = _navContext;
      if (ctx != null && ctx.mounted) return ctx;
      await Future<void>.delayed(step);
    }
    return null;
  }

  /// «Canlı Fal İsteği» — Kabul / Beklet / Reddet.
  static Future<LiveFortuneInviteAction?> showInviteDialog(
    FortuneIncomingSession session, {
    BuildContext? context,
  }) async {
    final ctx = context ?? await _waitForNavContext();
    if (ctx == null || !ctx.mounted) return null;
    return showFortuneRequestDialog(
      ctx,
      clientName: session.clientName,
      category: session.category,
      durationMinutes: session.durationMinutes,
      totalJeton: session.totalJeton,
    );
  }

  /// Kabul sonrası «Seansı Başlat» + seans odasına yönlendirme.
  static Future<bool> openSessionAfterAccept({
    required WidgetRef ref,
    required FortuneIncomingSession req,
    String? roomIdOverride,
    BuildContext? context,
  }) async {
    final navCtx = context ?? await _waitForNavContext();
    if (navCtx == null || !navCtx.mounted) return false;

    final repo = ref.read(liveFortuneRepositoryProvider);
    final roomPreview = await repo.fetchRoomInfo(req.sessionId);
    final clientJeton = roomPreview?.userJetonBalance ?? req.totalJeton;

    final startChoice = await showLiveFortuneSessionStartSheet(
      navCtx,
      clientName: req.clientName,
      clientJetonBalance: clientJeton,
    );
    if (!navCtx.mounted) return false;

    var durationMinutes = req.durationMinutes;
    var totalJeton = req.totalJeton;
    if (startChoice != null) {
      if (startChoice.durationMinutes > 0) {
        durationMinutes = startChoice.durationMinutes;
        await repo.tellerAddTime(
          sessionId: req.sessionId,
          minutes: startChoice.durationMinutes,
        );
      }
      if (startChoice.totalJeton > 0) {
        totalJeton = startChoice.totalJeton;
      }
      await repo.roomAction(req.sessionId, 'start_timer');
    }

    final status = await repo.fetchSessionStatus(req.sessionId);
    final user = ref.read(authControllerProvider).valueOrNull;
    final tellerId = req.tellerId.trim();
    LiveFortuneTellerEntity? teller;
    if (tellerId.isNotEmpty) {
      teller = await repo.fetchTeller(tellerId);
    }
    teller ??= await repo.fetchMyProfile();
    teller ??= LiveFortuneTellerEntity(
      id: tellerId.isNotEmpty ? tellerId : (user?.id ?? 'teller'),
      userId: user?.id,
      name: user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!.trim()
          : (user?.username ?? 'Falcı'),
      isOnline: true,
    );

    final session = LiveFortuneSessionEntity(
      sessionId: req.sessionId,
      teller: teller,
      durationMinutes: durationMinutes > 0
          ? durationMinutes
          : (status?.durationMinutes ?? req.durationMinutes),
      totalJeton: totalJeton > 0
          ? totalJeton
          : (status?.totalJeton ?? req.totalJeton),
      tellerUserId: status?.tellerUserId ?? req.tellerUserId ?? teller.trtcUserId,
      clientId: req.clientId,
      isClient: false,
      trtcRoomIdOverride:
          roomIdOverride ?? status?.trtcRoomId ?? req.sessionId,
    );
    if (!navCtx.mounted) return false;
    await navCtx.push(
      '/canli-falcilar/${teller.id}/session',
      extra: session,
    );
    return true;
  }
}
