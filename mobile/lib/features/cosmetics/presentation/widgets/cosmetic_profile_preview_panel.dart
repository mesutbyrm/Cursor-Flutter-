import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/cosmetic_item.dart';
import '../../domain/cosmetic_slot.dart';
import '../providers/cosmetics_providers.dart';
import 'cosmetic_asset_image.dart';
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
    this.overrides = const {},
    this.entranceToken = 0,
  });

  final CosmeticSlot activeSlot;

  /// Canlı önizleme: listede dokunulan (henüz uygulanmamış) öğeler. Anahtar
  /// varsa değer kullanılır (`null` = varsayılan).
  final Map<CosmeticSlot, CosmeticItem?> overrides;

  /// Değişince giriş efekti otomatik oynatılır (giriş önizlemesi).
  final int entranceToken;

  @override
  ConsumerState<CosmeticProfilePreviewPanel> createState() =>
      _CosmeticProfilePreviewPanelState();
}

class _CosmeticProfilePreviewPanelState
    extends ConsumerState<CosmeticProfilePreviewPanel> {
  var _showEntrance = false;
  var _entranceRun = 0;

  void _playEntrance() {
    setState(() {
      _showEntrance = true;
      _entranceRun++;
    });
  }

  @override
  void didUpdateWidget(covariant CosmeticProfilePreviewPanel old) {
    super.didUpdateWidget(old);
    if (widget.entranceToken != old.entranceToken &&
        widget.overrides[CosmeticSlot.entranceAnimation] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playEntrance();
      });
    }
  }

  CosmeticItem? _pick(CosmeticSlot s, CosmeticItem? equipped) =>
      widget.overrides.containsKey(s) ? widget.overrides[s] : equipped;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final display = user?.display ?? 'Kullanıcı Adı';
    final username = user?.username ?? 'kullanici';
    final avatarUrl = user?.avatarUrl;

    final frame = _pick(
        CosmeticSlot.profileFrame, ref.watch(resolvedProfileFrameProvider));
    final nameFx = _pick(
        CosmeticSlot.nameEffect, ref.watch(resolvedNameEffectProvider));
    final profileFx = _pick(
        CosmeticSlot.profileEffect, ref.watch(resolvedProfileEffectProvider));
    final entrance = _pick(CosmeticSlot.entranceAnimation,
        ref.watch(resolvedEntranceEffectProvider));
    final bubble = _pick(
        CosmeticSlot.chatBubble, ref.watch(resolvedChatBubbleProvider));
    final mic = _pick(CosmeticSlot.microphoneFrame,
        ref.watch(resolvedMicrophoneFrameProvider));
    final accessory = _pick(CosmeticSlot.avatarAccessory,
        ref.watch(resolvedAvatarAccessoryProvider));

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
                          if (accessory?.imageUrl != null)
                            _AccessoryOverlay(item: accessory!, size: 88),
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
                key: ValueKey('entrance-${entrance.id}-$_entranceRun'),
                userName: display,
                effectKind: entrance.effectKind,
                imageUrl: entrance.imageUrl,
                assetType: entrance.assetType,
                durationMs: entrance.durationMs,
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
          child: CosmeticChatBubbleStyle.bubble(
            bubble,
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
          'Bir öğeye dokun → burada nasıl göründüğünü gör → «Uygula».',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
    };
  }
}

/// Avatar aksesuarı (şapka/taç üstte, gözlük ortada, kanat arkada).
class _AccessoryOverlay extends StatelessWidget {
  const _AccessoryOverlay({required this.item, required this.size});

  final CosmeticItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final slot = (item.accessorySlot ?? 'other').toLowerCase();
    final img = CosmeticAssetImage(url: item.imageUrl!, fit: BoxFit.contain);
    return switch (slot) {
      'hat' || 'crown' => Positioned(
          top: -size * 0.38,
          left: size * 0.18,
          width: size * 0.64,
          height: size * 0.5,
          child: IgnorePointer(child: img),
        ),
      'glasses' || 'mask' => Positioned(
          top: size * (slot == 'mask' ? 0.42 : 0.3),
          left: size * 0.2,
          width: size * 0.6,
          height: size * 0.3,
          child: IgnorePointer(child: img),
        ),
      'wings' => Positioned(
          top: -size * 0.1,
          left: -size * 0.35,
          width: size * 1.7,
          height: size * 1.2,
          child: IgnorePointer(child: Opacity(opacity: 0.9, child: img)),
        ),
      _ => Positioned(
          top: -size * 0.12,
          right: -size * 0.12,
          width: size * 0.42,
          height: size * 0.42,
          child: IgnorePointer(child: img),
        ),
    };
  }
}
