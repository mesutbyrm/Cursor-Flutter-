import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_request_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_live_event_bus.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_cancel_signal.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_async_views.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_invite_diagnostic_card.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_recent_sessions_panel.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_rtc_session_report_card.dart';

class PsychicTellerDashboardState {
  const PsychicTellerDashboardState({
    this.profile,
    this.requests = const [],
    this.loading = true,
    this.togglingOnline = false,
    this.processingId,
    this.loadError,
  });

  final PsychicEntity? profile;
  final List<PsychicRequestEntity> requests;
  final bool loading;
  final bool togglingOnline;
  final String? processingId;
  final String? loadError;

  PsychicTellerDashboardState copyWith({
    PsychicEntity? profile,
    List<PsychicRequestEntity>? requests,
    bool? loading,
    bool? togglingOnline,
    String? processingId,
    String? loadError,
    bool clearProcessing = false,
    bool clearLoadError = false,
  }) {
    return PsychicTellerDashboardState(
      profile: profile ?? this.profile,
      requests: requests ?? this.requests,
      loading: loading ?? this.loading,
      togglingOnline: togglingOnline ?? this.togglingOnline,
      processingId:
          clearProcessing ? null : (processingId ?? this.processingId),
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
    );
  }
}

class PsychicTellerDashboardController
    extends AutoDisposeNotifier<PsychicTellerDashboardState> {
  Timer? _poll;
  StreamSubscription<PsychicRequestEntity>? _liveBusSub;

  @override
  PsychicTellerDashboardState build() {
    ref.onDispose(() {
      _poll?.cancel();
      _liveBusSub?.cancel();
    });
    _liveBusSub?.cancel();
    _liveBusSub =
        ref.read(psychicLiveEventBusProvider).stream.listen(_onLiveRequest);
    ref.listen<PsychicSessionCancelEvent?>(
      psychicSessionCancelSignalProvider,
      (prev, next) {
        if (next == null) return;
        _removeRequest(next.sessionId);
      },
    );
    Future.microtask(refresh);
    _schedulePoll();
    return const PsychicTellerDashboardState();
  }

  void _schedulePoll() {
    _poll?.cancel();
    // PsychicIncomingHost SSE + event bus gerçek zamanlı; HTTP yalnızca yedek.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _pollRequests());
  }

  void _onLiveRequest(PsychicRequestEntity req) {
    if (!req.isPending) return;
    final profile = state.profile;
    if (profile == null || !profile.isUsable) return;
    final tellerId = req.tellerId.trim();
    if (tellerId.isNotEmpty && tellerId != profile.id) return;
    final list = [...state.requests];
    list.removeWhere((r) => r.sessionId == req.sessionId);
    list.insert(0, req);
    state = state.copyWith(requests: list);
  }

  void _removeRequest(String sessionId) {
    if (sessionId.isEmpty) return;
    final next = state.requests
        .where((r) => r.sessionId != sessionId)
        .toList(growable: false);
    if (next.length == state.requests.length) return;
    state = state.copyWith(requests: next);
  }

  Future<PsychicEntity?> _profileWithServerOnline(PsychicEntity? profile) async {
    if (profile == null) return null;
    final onlineMap =
        await ref.read(livePsychicsRepositoryProvider).fetchOnlineStatus();
    if (onlineMap == null) return profile;
    final isOnline = onlineMap['isOnline'] == true ||
        onlineMap['online'] == true ||
        onlineMap['status']?.toString().toLowerCase() == 'online';
    return PsychicEntity(
      id: profile.id,
      userId: profile.userId,
      name: profile.name,
      bio: profile.bio,
      avatarUrl: profile.avatarUrl,
      isOnline: isOnline,
      rating: profile.rating,
      reviewCount: profile.reviewCount,
      pricePerMinute: profile.pricePerMinute,
      specialties: profile.specialties,
      category: profile.category,
      applicationStatus: profile.applicationStatus,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearLoadError: true);
    try {
      var approved = ref.read(approvedPsychicProvider);
      if (!approved.checked || approved.profile == null) {
        await ref.read(approvedPsychicProvider.notifier).refresh();
        approved = ref.read(approvedPsychicProvider);
      }
      var profile = approved.profile ??
          await ref.read(livePsychicsRepositoryProvider).fetchMyProfile();
      profile = await _profileWithServerOnline(profile);
      state = state.copyWith(
        profile: profile,
        loading: false,
        clearLoadError: true,
      );
      await _pollRequests();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        loadError: ApiException.userMessage(e),
      );
    }
  }

  Future<void> _pollRequests() async {
    final profile = state.profile;
    if (profile == null || !profile.isUsable) return;
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final incoming = await ref.read(livePsychicsRepositoryProvider).fetchIncomingRequests(
          currentUserId: userId,
          tellerProfileId: profile.id,
        );
    state = state.copyWith(
      requests: incoming.where((r) => r.isPending).toList(growable: false),
    );
  }

  Future<void> toggleOnline() async {
    final profile = state.profile;
    if (profile == null) return;
    state = state.copyWith(togglingOnline: true);
    try {
      await ref.read(livePsychicsRepositoryProvider).setOnline(
            online: !profile.isOnline,
          );
      state = state.copyWith(
        profile: PsychicEntity(
          id: profile.id,
          userId: profile.userId,
          name: profile.name,
          bio: profile.bio,
          avatarUrl: profile.avatarUrl,
          isOnline: !profile.isOnline,
          rating: profile.rating,
          reviewCount: profile.reviewCount,
          pricePerMinute: profile.pricePerMinute,
          specialties: profile.specialties,
          category: profile.category,
          applicationStatus: profile.applicationStatus,
        ),
        togglingOnline: false,
      );
    } catch (e) {
      state = state.copyWith(togglingOnline: false);
      rethrow;
    }
  }

  Future<void> reject(PsychicRequestEntity req) async {
    state = state.copyWith(processingId: req.sessionId);
    await ref
        .read(livePsychicsRepositoryProvider)
        .respondSession(req.sessionId, action: 'reject');
    state = state.copyWith(
      requests: state.requests
          .where((r) => r.sessionId != req.sessionId)
          .toList(growable: false),
      clearProcessing: true,
    );
  }

  Future<bool> accept(
    BuildContext context,
    PsychicRequestEntity req,
  ) async {
    state = state.copyWith(processingId: req.sessionId);
    final respond = await ref
        .read(livePsychicsRepositoryProvider)
        .respondSession(req.sessionId, action: 'accept');
    if (!respond.success) {
      state = state.copyWith(clearProcessing: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kabul sunucuya iletilemedi. Tekrar deneyin.'),
          ),
        );
      }
      return false;
    }

    final profile = state.profile;
    final user = ref.read(authControllerProvider).valueOrNull;
    final psychic = profile ??
        PsychicEntity(
          id: req.tellerId,
          userId: req.tellerUserId,
          name: user?.displayName ?? 'Falcı',
          isOnline: true,
        );

    final session = PsychicSessionEntity(
      sessionId: req.sessionId,
      psychic: psychic,
      durationMinutes: req.durationMinutes,
      totalJeton: req.totalJeton,
      tellerUserId: req.tellerUserId ?? psychic.trtcUserId,
      clientId: req.clientId,
      isClient: false,
      trtcRoomIdOverride: respond.roomId ?? req.sessionId,
      fortuneType: req.fortuneType,
    );

    state = state.copyWith(
      requests: state.requests
          .where((r) => r.sessionId != req.sessionId)
          .toList(growable: false),
      clearProcessing: true,
    );

    if (context.mounted) {
      await context.push(
        '/canli-falcilar/${psychic.id}/session',
        extra: session,
      );
    }
    return true;
  }
}

final psychicTellerDashboardProvider = AutoDisposeNotifierProvider<
    PsychicTellerDashboardController, PsychicTellerDashboardState>(
  PsychicTellerDashboardController.new,
);

/// Onaylı falcı paneli — bekleyen istekler ve kabul/red.
class PsychicTellerDashboardScreen extends ConsumerWidget {
  const PsychicTellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(
      psychicTellerDashboardProvider.select((s) => s.loading),
    );
    final togglingOnline = ref.watch(
      psychicTellerDashboardProvider.select((s) => s.togglingOnline),
    );
    final requests = ref.watch(
      psychicTellerDashboardProvider.select((s) => s.requests),
    );
    final processingId = ref.watch(
      psychicTellerDashboardProvider.select((s) => s.processingId),
    );
    final dashProfile = ref.watch(
      psychicTellerDashboardProvider.select((s) => s.profile),
    );
    final loadError = ref.watch(
      psychicTellerDashboardProvider.select((s) => s.loadError),
    );
    final approved = ref.watch(approvedPsychicProvider);
    final profile = dashProfile ?? approved.profile;

    if ((loading || (approved.loading && !approved.checked)) &&
        profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (loadError != null && (profile == null || !profile.isUsable)) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0618),
        appBar: AppBar(
          title: const Text('Falcı Paneli'),
          backgroundColor: Colors.transparent,
        ),
        body: CosmicGalaxyBackground(
          child: PsychicErrorView(
            message: loadError,
            onRetry: () =>
                ref.read(psychicTellerDashboardProvider.notifier).refresh(),
          ),
        ),
      );
    }

    if (profile == null || !profile.isUsable) {
      final status = profile?.applicationStatus ?? 'yok';
      return Scaffold(
        backgroundColor: const Color(0xFF0D0618),
        appBar: AppBar(
          title: const Text('Falcı Paneli'),
          backgroundColor: Colors.transparent,
        ),
        body: CosmicGalaxyBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    profile == null
                        ? Icons.workspace_premium_outlined
                        : Icons.hourglass_top_rounded,
                    size: 52,
                    color: context.colors.onSurfaceMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile == null
                        ? 'Henüz falcı değilsiniz'
                        : 'Onay bekleniyor',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile == null
                        ? 'Falcı başvurunuz admin panelinden onaylandıktan sonra bu panel açılır.'
                        : 'Başvuru durumu: $status. Yönetici onayından sonra panele erişebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.push(
                      profile == null ? '/falci-ol' : '/canli-falcilar/apply',
                    ),
                    child: Text(
                      profile == null ? 'Falcı Ol' : 'Başvuru Durumu',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0618),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Falcı Paneli'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(psychicTellerDashboardProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: CosmicGalaxyBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(psychicTellerDashboardProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: (kDebugMode ? 9 : 7) + requests.length,
              itemBuilder: (context, index) {
                final debugSlotCount = kDebugMode ? 2 : 0;
                const recentSessionsIndex = 4;
                final requestsHeaderIndex = recentSessionsIndex + 1 + debugSlotCount;
                final requestsEmptyIndex = requestsHeaderIndex + 1;
                final requestsStartIndex = requestsEmptyIndex + 1;
                if (index == 0) {
                  return RepaintBoundary(
                    child: _ProfileHeader(
                      profile: profile,
                      toggling: togglingOnline,
                      onToggleOnline: () async {
                        try {
                          await ref
                              .read(psychicTellerDashboardProvider.notifier)
                              .toggleOnline();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ApiException.userMessage(e)),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }
                if (index == 1) {
                  return RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _TellerStatGrid(
                        profile: profile,
                        pendingCount: requests.length,
                      ),
                    ),
                  );
                }
                if (index == 2) {
                  return RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _QuickActions(profile: profile),
                    ),
                  );
                }
                if (index == 3) {
                  return RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _TellerStatsPanel(tellerId: profile.id),
                    ),
                  );
                }
                if (index == recentSessionsIndex) {
                  return const RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: PsychicRecentSessionsPanel(),
                    ),
                  );
                }
                if (kDebugMode && index == recentSessionsIndex + 1) {
                  return const RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: PsychicInviteDiagnosticCard(),
                    ),
                  );
                }
                if (kDebugMode && index == recentSessionsIndex + 2) {
                  return const RepaintBoundary(
                    child: PsychicRtcSessionReportCard(),
                  );
                }
                if (index == requestsHeaderIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 12),
                    child: Text(
                      'Bekleyen talepler (${requests.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  );
                }
                if (index == requestsEmptyIndex) {
                  if (requests.isEmpty) {
                    return Text(
                      profile.isOnline
                          ? 'Bekleyen talep yok. Danışanlar sizi listede görebilir.'
                          : 'Çevrimiçi olduğunuzda gelen talepler burada görünür.',
                      style: TextStyle(color: context.colors.onSurfaceMuted),
                    );
                  }
                  return const SizedBox.shrink();
                }
                final req = requests[index - requestsStartIndex];
                return RepaintBoundary(
                  child: _PendingTile(
                    request: req,
                    processing: processingId == req.sessionId,
                    onAccept: () => ref
                        .read(psychicTellerDashboardProvider.notifier)
                        .accept(context, req),
                    onReject: () => ref
                        .read(psychicTellerDashboardProvider.notifier)
                        .reject(req),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TellerStatGrid extends StatelessWidget {
  const _TellerStatGrid({
    required this.profile,
    required this.pendingCount,
  });

  final PsychicEntity profile;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Puan',
            value: profile.rating > 0
                ? profile.rating.toStringAsFixed(1)
                : '—',
            icon: Icons.star_rounded,
            color: const Color(0xFFFFD54F),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Ücret',
            value: profile.pricePerMinute > 0
                ? '${profile.pricePerMinute} j/dk'
                : '—',
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFF00E676),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Bekleyen',
            value: '$pendingCount',
            icon: Icons.pending_actions_rounded,
            color: AppThemeColors.accentPurple,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.profile});

  final PsychicEntity profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/canli-falcilar/${profile.id}'),
            icon: const Icon(Icons.person_outline_rounded, size: 18),
            label: const Text('Profilim'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/profile/earnings'),
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: const Text('Kazançlar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TellerStatsPanel extends ConsumerWidget {
  const _TellerStatsPanel({required this.tellerId});

  final String tellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awards = ref.watch(psychicAwardsProvider(tellerId));
    final gifts = ref.watch(psychicGiftsProvider(tellerId));

    return awards.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => _MiniRetry(
        message: ApiException.userMessage(e),
        onRetry: () => ref.invalidate(psychicAwardsProvider(tellerId)),
      ),
      data: (awardList) => gifts.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => _MiniRetry(
          message: ApiException.userMessage(e),
          onRetry: () => ref.invalidate(psychicGiftsProvider(tellerId)),
        ),
        data: (giftList) {
          if (awardList.isEmpty && giftList.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (awardList.isNotEmpty) ...[
                const Text(
                  'Ödüller',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...awardList.take(5).map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Color(0xFFFFD54F),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                a.title.isNotEmpty ? a.title : a.awardType,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
              ],
              if (giftList.isNotEmpty) ...[
                const Text(
                  'Hediyeler',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...giftList.take(5).map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard_rounded,
                              color: Color(0xFFFF4081),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                g.senderName,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              '${g.giftCount}×',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.toggling,
    required this.onToggleOnline,
  });

  final PsychicEntity profile;
  final bool toggling;
  final Future<void> Function() onToggleOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const UserAvatar(radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  profile.isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                  style: TextStyle(
                    color: profile.isOnline
                        ? const Color(0xFF00E676)
                        : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: profile.isOnline,
            onChanged: toggling ? null : (_) => unawaited(onToggleOnline()),
          ),
        ],
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({
    required this.request,
    required this.processing,
    required this.onAccept,
    required this.onReject,
  });

  final PsychicRequestEntity request;
  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.clientName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              '${request.durationMinutes} dk · ${request.totalJeton} jeton',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: processing ? null : onAccept,
                    child: processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kabul'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: processing ? null : onReject,
                    child: const Text('Reddet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRetry extends StatelessWidget {
  const _MiniRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}
