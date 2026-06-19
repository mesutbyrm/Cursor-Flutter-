import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_request_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';

class PsychicTellerDashboardState {
  const PsychicTellerDashboardState({
    this.profile,
    this.requests = const [],
    this.loading = true,
    this.togglingOnline = false,
    this.processingId,
  });

  final PsychicEntity? profile;
  final List<PsychicRequestEntity> requests;
  final bool loading;
  final bool togglingOnline;
  final String? processingId;

  PsychicTellerDashboardState copyWith({
    PsychicEntity? profile,
    List<PsychicRequestEntity>? requests,
    bool? loading,
    bool? togglingOnline,
    String? processingId,
    bool clearProcessing = false,
  }) {
    return PsychicTellerDashboardState(
      profile: profile ?? this.profile,
      requests: requests ?? this.requests,
      loading: loading ?? this.loading,
      togglingOnline: togglingOnline ?? this.togglingOnline,
      processingId:
          clearProcessing ? null : (processingId ?? this.processingId),
    );
  }
}

class PsychicTellerDashboardController
    extends AutoDisposeNotifier<PsychicTellerDashboardState> {
  Timer? _poll;

  @override
  PsychicTellerDashboardState build() {
    ref.onDispose(() => _poll?.cancel());
    Future.microtask(refresh);
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _pollRequests());
    return const PsychicTellerDashboardState();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    final repo = ref.read(livePsychicsRepositoryProvider);
    final profile = await repo.fetchMyProfile();
    state = state.copyWith(profile: profile, loading: false);
    await _pollRequests();
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
    final ok = await ref.read(livePsychicsRepositoryProvider).setOnline(
          online: !profile.isOnline,
        );
    if (ok) {
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
    } else {
      state = state.copyWith(togglingOnline: false);
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
    final dash = ref.watch(psychicTellerDashboardProvider);
    final approved = ref.watch(approvedPsychicProvider);
    final profile = dash.profile ?? approved.valueOrNull?.profile;

    if (dash.loading || approved.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null || !profile.isApproved) {
      return Scaffold(
        appBar: AppBar(title: const Text('Falcı Panel')),
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
        title: const Text('Falcı Panel'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(psychicTellerDashboardProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(psychicTellerDashboardProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _ProfileHeader(
              profile: profile,
              toggling: dash.togglingOnline,
              onToggleOnline: () =>
                  ref.read(psychicTellerDashboardProvider.notifier).toggleOnline(),
            ),
            const SizedBox(height: 16),
            Text(
              'Bekleyen: ${dash.requests.length}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (dash.requests.isEmpty)
              Text(
                'Bekleyen talep yok. Çevrimiçi olduğunuzda istekler burada görünür.',
                style: TextStyle(color: context.colors.onSurfaceMuted),
              )
            else
              ...dash.requests.map(
                (req) => _PendingTile(
                  request: req,
                  processing: dash.processingId == req.sessionId,
                  onAccept: () => ref
                      .read(psychicTellerDashboardProvider.notifier)
                      .accept(context, req),
                  onReject: () => ref
                      .read(psychicTellerDashboardProvider.notifier)
                      .reject(req),
                ),
              ),
          ],
        ),
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
  final VoidCallback onToggleOnline;

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
            onChanged: toggling ? null : (_) => onToggleOnline(),
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
                        : const Text('Kabul Et'),
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
