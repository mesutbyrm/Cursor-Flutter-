import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../domain/cosmetic_effect_kind.dart';
import '../../domain/cosmetic_item.dart';
import '../../domain/cosmetic_slot.dart';
import '../providers/cosmetics_providers.dart';
import '../widgets/cosmetic_avatar_frame.dart';
import '../widgets/cosmetic_chat_bubble.dart';
import '../widgets/cosmetic_mic_frame_ring.dart';
import '../widgets/cosmetic_name_label.dart';

/// Gold+ — profil kozmetikleri (çerçeve, isim, efekt, giriş, balon, mikrofon).
class ProfileCosmeticsPage extends ConsumerStatefulWidget {
  const ProfileCosmeticsPage({super.key});

  @override
  ConsumerState<ProfileCosmeticsPage> createState() =>
      _ProfileCosmeticsPageState();
}

class _ProfileCosmeticsPageState extends ConsumerState<ProfileCosmeticsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _slots = [
    CosmeticSlot.profileFrame,
    CosmeticSlot.nameEffect,
    CosmeticSlot.profileEffect,
    CosmeticSlot.entranceAnimation,
    CosmeticSlot.chatBubble,
    CosmeticSlot.microphoneFrame,
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _slots.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = ref.watch(vipTierProvider);
    final canCustomize = tier.index >= VipTier.gold.index;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Premium Profil',
          body: canCustomize
              ? Column(
                  children: [
                    TabBar(
                      controller: _tabs,
                      isScrollable: true,
                      tabs: [
                        for (final slot in _slots) Tab(text: _tabLabel(slot)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          for (final slot in _slots)
                            _CosmeticGrid(
                              slot: slot,
                              catalog: mergedCatalogForSlot(ref, slot),
                              tier: tier,
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Profil çerçevesi ve efekt seçimi Gold üyelik gerektirir.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.push('/vip-gold'),
                          child: const Text('Gold\'a yükselt'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  String _tabLabel(CosmeticSlot slot) => switch (slot) {
        CosmeticSlot.profileFrame => 'Çerçeve',
        CosmeticSlot.nameEffect => 'İsim',
        CosmeticSlot.profileEffect => 'Efekt',
        CosmeticSlot.entranceAnimation => 'Giriş',
        CosmeticSlot.chatBubble => 'Balon',
        CosmeticSlot.microphoneFrame => 'Mikrofon',
        CosmeticSlot.badge => 'Rozet',
      };
}

class _CosmeticGrid extends ConsumerWidget {
  const _CosmeticGrid({
    required this.slot,
    required this.catalog,
    required this.tier,
  });

  final CosmeticSlot slot;
  final List<CosmeticItem> catalog;
  final VipTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadout = ref.watch(cosmeticLoadoutProvider).valueOrNull;
    final equipped = loadout?.idFor(slot);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: catalog.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          final selected = equipped == null;
          return _CosmeticTile(
            title: 'Varsayılan',
            selected: selected,
            child: _defaultPreview(slot),
            onTap: () => ref
                .read(cosmeticLoadoutProvider.notifier)
                .equip(slot, null),
          );
        }
        final item = catalog[i - 1];
        final unlocked = item.isUnlockedFor(tier: tier);
        final selected = equipped == item.id;
        return _CosmeticTile(
          title: item.name,
          selected: selected,
          locked: !unlocked,
          child: _itemPreview(slot, item),
          onTap: unlocked
              ? () => ref
                  .read(cosmeticLoadoutProvider.notifier)
                  .equip(slot, item.id)
              : null,
        );
      },
    );
  }

  Widget _defaultPreview(CosmeticSlot slot) {
    return switch (slot) {
      CosmeticSlot.chatBubble => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: CosmeticChatBubbleStyle.decoration(null),
          child: const Text('Merhaba', style: TextStyle(fontSize: 12)),
        ),
      CosmeticSlot.entranceAnimation => const Icon(Icons.door_front_door, size: 40),
      CosmeticSlot.microphoneFrame => const CircleAvatar(
          radius: 28,
          child: Icon(Icons.mic),
        ),
      _ => const CircleAvatar(
          radius: 28,
          child: Icon(Icons.person),
        ),
    };
  }

  Widget _itemPreview(CosmeticSlot slot, CosmeticItem item) {
    return switch (slot) {
      CosmeticSlot.nameEffect => CosmeticNameLabel(
          text: 'Ad',
          item: item,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      CosmeticSlot.chatBubble => CosmeticChatBubbleStyle.preview(item),
      CosmeticSlot.entranceAnimation => Icon(
          _entranceIcon(item.effectKind),
          size: 44,
          color: _entranceColor(item.effectKind),
        ),
      CosmeticSlot.microphoneFrame => CosmeticMicFrameRing(
          item: item,
          size: 52,
          micOpen: true,
          child: const CircleAvatar(
            radius: 26,
            child: Icon(Icons.mic, size: 28),
          ),
        ),
      _ => CosmeticAvatarFrame(
          item: item,
          size: 64,
          showParticles: slot == CosmeticSlot.profileEffect,
          child: const CircleAvatar(
            radius: 26,
            child: Icon(Icons.person, size: 28),
          ),
        ),
    };
  }

  IconData _entranceIcon(CosmeticEffectKind k) => switch (k) {
        CosmeticEffectKind.entranceDragon => Icons.whatshot_rounded,
        CosmeticEffectKind.entranceMeteor => Icons.brightness_2_rounded,
        CosmeticEffectKind.entranceWings => Icons.air_rounded,
        CosmeticEffectKind.entranceAngel => Icons.auto_awesome_rounded,
        CosmeticEffectKind.entranceFireworks => Icons.celebration_rounded,
        CosmeticEffectKind.entranceCrown => Icons.emoji_events_rounded,
        CosmeticEffectKind.entranceGalaxy => Icons.hub_rounded,
        CosmeticEffectKind.entranceGoldRain => Icons.water_drop_rounded,
        _ => Icons.stars_rounded,
      };

  Color _entranceColor(CosmeticEffectKind k) => switch (k) {
        CosmeticEffectKind.entranceDragon => const Color(0xFFFF5722),
        CosmeticEffectKind.entranceMeteor => const Color(0xFFFFEB3B),
        CosmeticEffectKind.entranceWings => const Color(0xFF80DEEA),
        CosmeticEffectKind.entranceAngel => Colors.white,
        CosmeticEffectKind.entranceFireworks => const Color(0xFFFF4081),
        CosmeticEffectKind.entranceCrown => const Color(0xFFFFD54F),
        CosmeticEffectKind.entranceGalaxy => const Color(0xFF7C4DFF),
        CosmeticEffectKind.entranceGoldRain => const Color(0xFFFFD54F),
        _ => const Color(0xFFB832FF),
      };
}

class _CosmeticTile extends StatelessWidget {
  const _CosmeticTile({
    required this.title,
    required this.child,
    required this.selected,
    this.locked = false,
    this.onTap,
  });

  final String title;
  final Widget child;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(opacity: locked ? 0.4 : 1, child: child),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              if (locked)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.lock, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
