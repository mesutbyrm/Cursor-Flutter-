import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/cosmetic_item.dart';
import '../../domain/cosmetic_slot.dart';
import '../providers/cosmetics_providers.dart';
import 'cosmetic_avatar_frame.dart';
import 'cosmetic_chat_bubble.dart';
import 'cosmetic_entrance_overlay.dart';
import 'cosmetic_mic_frame_ring.dart';
import 'cosmetic_name_label.dart';
import 'cosmetic_particle_overlay.dart';

/// Premium profil — seçilen kozmetiklerin profilde nasıl göründüğünü gösterir.
class CosmeticProfilePreviewPanel extends ConsumerStatefulWidget {
  const CosmeticProfilePreviewPanel({
    super.key,
    required this.activeSlot,
  });

  final CosmeticSlot activeSlot;

  @override
  ConsumerState<CosmeticProfilePreviewPanel> createState() =>
      _CosmeticProfilePreviewPanelState();
}

class _CosmeticProfilePreviewPanelState
    extends ConsumerState<CosmeticProfilePreviewPanel> {
  var _showEntrance = false;

  void _playEntrance() {
    setState(() => _showEntrance = true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final display = user?.display ?? 'Kullanıcı Adı';
    final username = user?.username ?? 'kullanici';
    final avatarUrl = user?.avatarUrl;

    final frame = ref.watch(resolvedProfileFrameProvider);
    final nameFx = ref.watch(resolvedNameEffectProvider);
    final profileFx = ref.watch(resolvedProfileEffectProvider);
    final entrance = ref.watch(resolvedEntranceEffectProvider);
    final bubble = ref.watch(resolvedChatBubbleProvider);
    final mic = ref.watch(resolvedMicrophoneFrameProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1030), Color(0xFF0D1528)],
        ),
        border: Border.all(color: const Color(0xFFB832FF).withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB832FF).withValues(alpha: 0.22),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CoverStrip(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          CosmeticAvatarFrame(
                            item: frame,
                            size: 88,
                            showParticles: false,
                            child: UserAvatar(
                              url: avatarUrl,
                              radius: 36,
                            ),
                          ),
                          if (profileFx != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: _ProfileFxHost(effect: profileFx),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CosmeticNameLabel(
                              text: display,
                              item: nameFx,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 8),
                                ],
                              ),
                            ),
                            Text(
                              '@$username',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _ContextPreview(
                  slot: widget.activeSlot,
                  bubble: bubble,
                  mic: mic,
                  entrance: entrance,
                  onPlayEntrance: entrance != null ? _playEntrance : null,
                ),
              ),
            ],
          ),
          if (_showEntrance && entrance != null)
            Positioned.fill(
              child: CosmeticEntranceOverlay(
                userName: display,
                effectKind: entrance.effectKind,
                onFinished: () {
                  if (mounted) setState(() => _showEntrance = false);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CoverStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B21B6), Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
      ),
      alignment: Alignment.topRight,
      padding: const EdgeInsets.only(top: 8, right: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Profil önizleme',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _ProfileFxHost extends StatefulWidget {
  const _ProfileFxHost({required this.effect});

  final CosmeticItem effect;

  @override
  State<_ProfileFxHost> createState() => _ProfileFxHostState();
}

class _ProfileFxHostState extends State<_ProfileFxHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CosmeticParticleOverlay(
      kind: widget.effect.effectKind,
      size: 88,
      controller: _ctrl,
    );
  }
}

class _ContextPreview extends StatelessWidget {
  const _ContextPreview({
    required this.slot,
    this.bubble,
    this.mic,
    this.entrance,
    this.onPlayEntrance,
  });

  final CosmeticSlot slot;
  final CosmeticItem? bubble;
  final CosmeticItem? mic;
  final CosmeticItem? entrance;
  final VoidCallback? onPlayEntrance;

  @override
  Widget build(BuildContext context) {
    return switch (slot) {
      CosmeticSlot.chatBubble => Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: CosmeticChatBubbleStyle.decoration(bubble),
            child: const Text(
              'Sohbette böyle görünür 💬',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      CosmeticSlot.microphoneFrame => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (mic != null)
              CosmeticMicFrameRing(
                item: mic!,
                size: 64,
                micOpen: true,
                child: const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.mic_rounded, size: 28),
                ),
              )
            else
              const CircleAvatar(
                radius: 32,
                child: Icon(Icons.mic_rounded, size: 28),
              ),
            const SizedBox(width: 12),
            Text(
              mic?.name ?? 'Varsayılan mikrofon',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      CosmeticSlot.entranceAnimation => Row(
          children: [
            Expanded(
              child: Text(
                entrance?.name ?? 'Varsayılan giriş',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onPlayEntrance,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Giriş efektini oynat'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      CosmeticSlot.nameEffect => Text(
          'İsim efekti profil başlığında yukarıda görünür.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      CosmeticSlot.profileEffect => Text(
          'Profil efekti avatar çevresinde parçacık olarak görünür.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      _ => Text(
          'Seçiminiz profilinizde anında uygulanır.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
    };
  }
}
