import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../providers/home_providers.dart';
import '../providers/teller_dashboard_provider.dart';
import '../providers/teller_profile_provider.dart';
import '../widgets/incoming_request_dialog.dart';
import '../widgets/live_fortune_session_start_sheet.dart';

/// Onaylı falcı kontrol paneli — pending poll + kabul/red popup.
class TellerDashboardScreen extends ConsumerStatefulWidget {
  const TellerDashboardScreen({super.key});

  @override
  ConsumerState<TellerDashboardScreen> createState() =>
      _TellerDashboardScreenState();
}

class _TellerDashboardScreenState extends ConsumerState<TellerDashboardScreen> {
  String? _shownPopupId;
  var _openingSession = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<TellerDashboardState>(tellerDashboardProvider, (prev, next) {
      final popupId = next.popupSessionId;
      if (popupId == null || popupId == _shownPopupId || _openingSession) {
        return;
      }
      FortuneIncomingSession? session;
      for (final s in next.pendingSessions) {
        if (s.sessionId == popupId) {
          session = s;
          break;
        }
      }
      if (session == null) return;
      _shownPopupId = popupId;
      final captured = session;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_showIncomingPopup(captured));
      });
    });

    final dash = ref.watch(tellerDashboardProvider);
    final approved = ref.watch(approvedTellerProvider);
    final profile = dash.profile ?? approved.profile;

    if (approved.loading || dash.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null || !profile.isApproved) {
      return Scaffold(
        appBar: AppBar(title: const Text('Falcı Paneli')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              profile == null
                  ? 'Falcı profili bulunamadı. Başvurunuz onaylandıktan sonra panel açılır.'
                  : 'Başvuru durumu: ${profile.applicationStatus ?? "bilinmiyor"}. Onay bekleniyor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.onSurfaceMuted),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0618),
      appBar: AppBar(
        title: const Text('Falcı Paneli'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(tellerDashboardProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tellerDashboardProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _ProfileHeader(
              profile: profile,
              toggling: dash.togglingOnline,
              onToggleOnline: () =>
                  ref.read(tellerDashboardProvider.notifier).toggleOnline(),
            ),
            const SizedBox(height: 16),
            _StatGrid(
              rating: profile.rating,
              totalSessions: profile.totalSessions,
              totalEarnings: profile.totalEarnings,
              activeSessions: dash.activeSessionCount,
            ),
            const SizedBox(height: 20),
            _PendingBadge(count: dash.pendingCount),
            if (dash.lastApiLog != null) ...[
              const SizedBox(height: 8),
              Text(
                dash.lastApiLog!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (dash.pendingSessions.isEmpty)
              Text(
                'Bekleyen talep yok. Çevrimiçi olduğunuzda istekler burada görünür.',
                style: TextStyle(color: context.colors.onSurfaceMuted),
              )
            else
              ...dash.pendingSessions.map(
                (s) => _PendingTile(
                  session: s,
                  onTap: () => _showIncomingPopup(s),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showIncomingPopup(FortuneIncomingSession session) async {
    if (!mounted) return;
    await IncomingRequestDialog.show(
      context,
      session: session,
      onAccept: () => _handleAccept(session),
      onReject: () => ref
          .read(tellerDashboardProvider.notifier)
          .rejectSession(session),
    );
    ref.read(tellerDashboardProvider.notifier).clearPopup();
  }

  Future<void> _handleAccept(FortuneIncomingSession session) async {
    if (_openingSession) return;
    _openingSession = true;
    try {
      final respond = await ref
          .read(tellerDashboardProvider.notifier)
          .acceptSession(session);
      if (!mounted) return;
      if (!respond.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kabul sunucuya iletilemedi.')),
        );
        return;
      }

      final repo = ref.read(liveFortuneRepositoryProvider);
      final roomPreview = await repo.fetchRoomInfo(session.sessionId);
      final clientJeton = roomPreview?.userJetonBalance ?? session.totalJeton;

      if (!mounted) return;
      final startChoice = await showLiveFortuneSessionStartSheet(
        context,
        clientName: session.clientName,
        clientJetonBalance: clientJeton,
      );

      var durationMinutes = session.durationMinutes;
      var totalJeton = session.totalJeton;
      if (startChoice != null) {
        if (startChoice.durationMinutes > 0) {
          durationMinutes = startChoice.durationMinutes;
          await repo.tellerAddTime(
            sessionId: session.sessionId,
            minutes: startChoice.durationMinutes,
          );
        }
        if (startChoice.totalJeton > 0) totalJeton = startChoice.totalJeton;
        await repo.roomAction(session.sessionId, 'start_timer');
      }

      final status = await repo.fetchSessionStatus(session.sessionId);
      final teller = ref.read(tellerDashboardProvider).profile ??
          ref.read(approvedTellerProvider).profile;
      if (teller == null || !mounted) return;

      final liveSession = LiveFortuneSessionEntity(
        sessionId: session.sessionId,
        teller: teller,
        durationMinutes: durationMinutes > 0
            ? durationMinutes
            : (status?.durationMinutes ?? session.durationMinutes),
        totalJeton: totalJeton > 0
            ? totalJeton
            : (status?.totalJeton ?? session.totalJeton),
        tellerUserId:
            status?.tellerUserId ?? session.tellerUserId ?? teller.trtcUserId,
        clientId: session.clientId,
        isClient: false,
        trtcRoomIdOverride:
            respond.roomId ?? status?.trtcRoomId ?? session.sessionId,
      );

      if (!mounted) return;
      await context.push(
        '/canli-falcilar/${teller.id}/session',
        extra: liveSession,
      );
    } finally {
      _openingSession = false;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.toggling,
    required this.onToggleOnline,
  });

  final LiveFortuneTellerEntity profile;
  final bool toggling;
  final VoidCallback onToggleOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1450), Color(0xFF120A24)],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          UserAvatar(url: profile.avatarUrl, radius: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: profile.isOnline ? Colors.greenAccent : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      profile.isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: profile.isOnline,
            onChanged: toggling ? null : (_) => onToggleOnline(),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.rating,
    required this.totalSessions,
    required this.totalEarnings,
    required this.activeSessions,
  });

  final double rating;
  final int totalSessions;
  final int totalEarnings;
  final int activeSessions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _statCard('Puan', rating.toStringAsFixed(1)),
        _statCard('Toplam Seans', '$totalSessions'),
        _statCard('Kazanç (jeton)', '$totalEarnings'),
        _statCard('Aktif Seans', '$activeSessions'),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Bekleyen Talepler',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '($count)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.session, required this.onTap});

  final FortuneIncomingSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1235),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          session.clientName,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '${session.category} · ${session.durationMinutes} dk · ${session.totalJeton} jeton',
          style: const TextStyle(color: Colors.white60),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      ),
    );
  }
}
