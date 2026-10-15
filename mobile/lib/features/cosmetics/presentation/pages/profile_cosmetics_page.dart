import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../domain/cosmetic_effect_kind.dart';
import '../../domain/cosmetic_item.dart';
import '../../domain/cosmetic_slot.dart';
import '../providers/cosmetics_providers.dart';
import '../widgets/cosmetic_asset_image.dart';
import '../widgets/cosmetic_avatar_frame.dart';
import '../widgets/cosmetic_chat_bubble.dart';
import '../widgets/cosmetic_mic_frame_ring.dart';
import '../widgets/cosmetic_name_label.dart';
import '../widgets/cosmetic_profile_preview_panel.dart';

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

  /// Canlı önizleme — dokunulan ama henüz uygulanmamış öğeler.
  final Map<CosmeticSlot, CosmeticItem?> _preview = {};
  var _entranceToken = 0;
  var _applying = false;

  void _onPreview(CosmeticSlot slot, CosmeticItem? item) {
    setState(() {
      _preview[slot] = item;
      if (slot == CosmeticSlot.entranceAnimation && item != null) {
        _entranceToken++;
      }
    });
  }

  Future<void> _apply(CosmeticSlot slot) async {
    if (_applying || !_preview.containsKey(slot)) return;
    final item = _preview[slot];
    setState(() => _applying = true);
    try {
      await ref.read(cosmeticLoadoutProvider.notifier).equip(slot, item?.id);
      if (!mounted) return;
      setState(() => _preview.remove(slot));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null
                ? '${_tabLabel(slot)}: varsayılana döndü'
                : '${item.name} uygulandı ✓',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uygulanamadı, tekrar dene.')),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  static const _slots = [
    CosmeticSlot.profileFrame,
    CosmeticSlot.nameEffect,
    CosmeticSlot.profileEffect,
    CosmeticSlot.avatarAccessory,
    CosmeticSlot.entranceAnimation,
    CosmeticSlot.chatBubble,
    CosmeticSlot.microphoneFrame,
    CosmeticSlot.badge,
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _slots.length, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = ref.watch(vipTierProvider);
    final canCustomize = ref.watch(canCustomizeCosmeticsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: buildMembershipSettingsCosmeticsRowLabel(),
          body: canCustomize
              ? Column(
                  children: [
                    CosmeticProfilePreviewPanel(
                      activeSlot: _slots[_tabs.index],
                      overrides: _preview,
                      entranceToken: _entranceToken,
                    ),
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
                              previewing: _preview.containsKey(slot)
                                  ? (_preview[slot]?.id ?? '__default__')
                                  : null,
                              onPreview: (item) => _onPreview(slot, item),
                            ),
                        ],
                      ),
                    ),
                    _applyBar(_slots[_tabs.index], tier),
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

  /// Önizlenen öğe için «Uygula» / kilit çubuğu.
  Widget _applyBar(CosmeticSlot slot, VipTier tier) {
    if (!_preview.containsKey(slot)) return const SizedBox.shrink();
    final item = _preview[slot];
    final equipped = ref.watch(cosmeticLoadoutProvider).valueOrNull?.idFor(slot);
    if (item?.id == equipped) return const SizedBox.shrink();
    final unlocked = item == null || item.isUnlockedFor(tier: tier);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item == null
                    ? 'Varsayılan önizleniyor'
                    : unlocked
                        ? '${item.name} önizleniyor'
                        : '${item.name} · ${item.requiredTier.label} üyelik gerekir',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _preview.remove(slot)),
              child: const Text('Vazgeç'),
            ),
            const SizedBox(width: 4),
            unlocked
                ? FilledButton(
                    onPressed: _applying ? null : () => _apply(slot),
                    child: Text(_applying ? 'Uygulanıyor…' : 'Uygula'),
                  )
                : FilledButton(
                    onPressed: () => context.push('/premium-membership'),
                    child: const Text('Yükselt'),
                  ),
          ],
        ),
      ),
    );
  }

  String _tabLabel(CosmeticSlot slot) => switch (slot) {
        CosmeticSlot.profileFrame => 'Çerçeve',
        CosmeticSlot.nameEffect => 'İsim',
        CosmeticSlot.profileEffect => 'Efekt',
        CosmeticSlot.avatarAccessory => 'Aksesuar',
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
    required this.onPreview,
    this.previewing,
  });

  final CosmeticSlot slot;
  final List<CosmeticItem> catalog;
  final VipTier tier;

  /// Dokununca uygulamaz — önce üstte canlı önizler («Uygula» ile kaydedilir).
  final ValueChanged<CosmeticItem?> onPreview;

  /// Önizlenen öğe kimliği (`__default__` = varsayılan).
  final String? previewing;

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
            previewing: previewing == '__default__',
            child: _defaultPreview(slot),
            onTap: () => onPreview(null),
          );
        }
        final item = catalog[i - 1];
        final unlocked = item.isUnlockedFor(tier: tier);
        final selected = equipped == item.id;
        return _CosmeticTile(
          title: item.name,
          selected: selected,
          previewing: previewing == item.id,
          locked: !unlocked,
          child: _itemPreview(slot, item),
          // Kilitli öğeler de önizlenebilir (nasıl görüneceğini görmek için).
          onTap: () => onPreview(item),
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
      CosmeticSlot.entranceAnimation when item.imageUrl != null =>
        CosmeticAssetImage(
          url: item.imageUrl!,
          assetType: item.assetType,
          width: 64,
          height: 64,
        ),
      CosmeticSlot.avatarAccessory when item.imageUrl != null =>
        CosmeticAssetImage(url: item.imageUrl!, width: 64, height: 64),
      CosmeticSlot.entranceAnimation => Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _entranceColor(item.effectKind).withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(
            _entranceIcon(item.effectKind),
            size: 36,
            color: _entranceColor(item.effectKind),
            shadows: [
              Shadow(
                color: _entranceColor(item.effectKind).withValues(alpha: 0.8),
                blurRadius: 12,
              ),
            ],
          ),
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
          size: 72,
          showParticles: slot == CosmeticSlot.profileEffect,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: _glowFor(item.effectKind).withValues(alpha: 0.25),
            child: Icon(
              Icons.person_rounded,
              size: 30,
              color: _glowFor(item.effectKind),
            ),
          ),
        ),
    };
  }

  Color _glowFor(CosmeticEffectKind k) => switch (k) {
        CosmeticEffectKind.fire => const Color(0xFFFF5722),
        CosmeticEffectKind.diamond => const Color(0xFF80DEEA),
        CosmeticEffectKind.lightning => const Color(0xFFFFEB3B),
        CosmeticEffectKind.neonGlow => const Color(0xFF00E5FF),
        CosmeticEffectKind.crown => const Color(0xFFFFD54F),
        CosmeticEffectKind.rotatingLight => const Color(0xFFB832FF),
        _ => const Color(0xFFB832FF),
      };

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
    this.previewing = false,
    this.onTap,
  });

  final String title;
  final Widget child;
  final bool selected;
  final bool previewing;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: previewing
                ? Border.all(color: const Color(0xFF25F4EE), width: 2.5)
                : selected
                    ? Border.all(
                        color: scheme.primary.withValues(alpha: 0.85),
                        width: 2,
                      )
                    : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
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
                if (previewing)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Önizleniyor',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF25F4EE),
                      ),
                    ),
                  ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Profilde aktif',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
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
      ),
    );
  }
}
