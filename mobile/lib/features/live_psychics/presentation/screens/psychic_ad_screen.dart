import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:canlifal_social/features/fortune/data/services/rewarded_ad_service.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/agora/presentation/agora_room_manager.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

final _psychicAdNavProvider =
    StateProvider.autoDispose<PsychicSessionEntity?>((ref) => null);

final _psychicAdPermissionsProvider =
    StateProvider.autoDispose<bool>((ref) => false);

final _psychicAdLoadingProvider =
    StateProvider.autoDispose<bool>((ref) => true);

/// Falcı kabul ettikten sonra danışana gösterilen reklam geçişi.
class PsychicAdScreen extends ConsumerWidget {
  const PsychicAdScreen({super.key, required this.session});

  final PsychicSessionEntity session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsReady = ref.watch(_psychicAdPermissionsProvider);
    final adLoading = ref.watch(_psychicAdLoadingProvider);
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
                              canlifalImageProvider(psychic.avatarUrl!),
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
                if (adLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Reklam yükleniyor…',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Text(
                        permissionsReady
                            ? 'Canlı fal deneyiminiz başlıyor…'
                            : 'Kamera ve mikrofon izni isteniyor…',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ),
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

  final paidWithJeton = session.totalJeton > 0;
  if (!paidWithJeton) {
    final watched = await RewardedAdService.instance.show();
    if (!watched) {
      ref.read(_psychicAdLoadingProvider.notifier).state = false;
      return;
    }
  }

  ref.read(_psychicAdLoadingProvider.notifier).state = false;
  ref.read(_psychicAdNavProvider.notifier).state = session;
});
