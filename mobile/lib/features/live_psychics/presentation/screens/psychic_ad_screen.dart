import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_admin_ad_panel.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/agora/presentation/agora_room_manager.dart';

final _psychicAdNavProvider =
    StateProvider.autoDispose<PsychicSessionEntity?>((ref) => null);

final _psychicAdPermissionsProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Falcı kabul ettikten sonra danışana gösterilen reklam geçişi.
class PsychicAdScreen extends ConsumerWidget {
  const PsychicAdScreen({super.key, required this.session});

  final PsychicSessionEntity session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsReady = ref.watch(_psychicAdPermissionsProvider);
    ref.watch(_psychicAdInitProvider(session));
    final psychic = session.psychic;

    ref.listen<PsychicSessionEntity?>(_psychicAdNavProvider, (prev, next) {
      if (next == null) return;
      context.pushReplacement(
        '/canli-falcilar/${next.psychic.id}/session',
        extra: next,
      );
      ref.read(_psychicAdNavProvider.notifier).state = null;
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0618),
        body: CosmicGalaxyBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const SizedBox(height: 36),
                Center(
                  child: psychic.avatarUrl != null &&
                          psychic.avatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 52,
                          backgroundImage:
                              CachedNetworkImageProvider(psychic.avatarUrl!),
                        )
                      : const UserAvatar(radius: 52),
                ),
                const SizedBox(height: 12),
                Text(
                  psychic.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Randevu Al',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PsychicAdminAdPanel(
                  countdownSeconds: 4,
                  onCountdownFinished: () {
                    ref.read(_psychicAdNavProvider.notifier).state = session;
                  },
                  subtitle: permissionsReady
                      ? 'Canlı fal deneyiminiz birazdan başlayacak!'
                      : 'Kamera ve mikrofon izni isteniyor…',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _psychicAdInitProvider = FutureProvider.autoDispose
    .family<void, PsychicSessionEntity>((ref, session) async {
  await PsychicSessionStore.save(session);
  final ok = await AgoraRoomManager.requestPermissions(video: true);
  ref.read(_psychicAdPermissionsProvider.notifier).state = ok;
});
