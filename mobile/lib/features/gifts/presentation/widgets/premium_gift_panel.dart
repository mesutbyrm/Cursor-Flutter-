import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/config/env.dart';
import '../../../live/domain/entities/live_gift_type.dart';
import '../../../live/presentation/gifts/live_gift_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/premium_gift_catalog_2026.dart';
import '../../domain/gift_entity.dart';
import '../../domain/gift_platform.dart';
import '../../domain/gift_rarity.dart';
import '../providers/gift_providers.dart';
import 'top_gifters_leaderboard.dart';

/// TikTok benzeri premium hediye paneli — blur, neon, yatay liste, leaderboard sekmesi.
class PremiumGiftPanel extends ConsumerStatefulWidget {
  const PremiumGiftPanel({
    super.key,
    required this.controller,
    required this.streamId,
    required this.senderName,
    this.senderId,
    required this.onClose,
  });

  final LiveGiftController controller;
  final String streamId;
  final String senderName;
  final String? senderId;
  final VoidCallback onClose;

  @override
  ConsumerState<PremiumGiftPanel> createState() => _PremiumGiftPanelState();
}

class _PremiumGiftPanelState extends ConsumerState<PremiumGiftPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  LiveVideoGiftType? _selected;
  int _qty = 1;
  String _category = 'popular';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gifts = ref.watch(liveGiftCatalogProvider);
    final leaderboard = ref.watch(streamGiftLeaderboardProvider(widget.streamId));
    final coins = widget.controller.coinBalance ??
        ref.watch(coinBalanceProvider) ??
        0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppThemeColors.accentPurple.withValues(alpha: 0.42),
                const Color(0xFF0A0A14).withValues(alpha: 0.96),
              ],
            ),
            border: Border(
              top: BorderSide(color: AppThemeColors.accentPink.withValues(alpha: 0.5)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppThemeColors.accentPurple.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Text(
                      'Hediye Gönder',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    _CoinChip(coins: coins),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabs,
                indicatorColor: AppThemeColors.accentPink,
                labelColor: context.colors.onSurface,
                unselectedLabelColor: context.colors.onSurfaceMuted,
                tabs: const [
                  Tab(text: 'Hediyeler'),
                  Tab(text: 'Top Gifters'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _GiftsTab(
                      gifts: gifts,
                      category: _category,
                      onCategory: (c) => setState(() => _category = c),
                      selected: _selected,
                      qty: _qty,
                      sending: widget.controller.sending,
                      onSelect: (g) => setState(() => _selected = g),
                      onQty: (q) => setState(() => _qty = q),
                      onSend: _send,
                    ),
                    leaderboard.when(
                      loading: () =>
                          const TopGiftersLeaderboard(entries: [], loading: true),
                      error: (_, _) => const TopGiftersLeaderboard(entries: []),
                      data: (list) => SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: TopGiftersLeaderboard(entries: list),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 340.ms, curve: Curves.easeOutCubic);
  }

  Future<void> _send() async {
    final g = _selected;
    if (g == null) return;
    await widget.controller.send(
      gift: g,
      senderName: widget.senderName,
      senderId: widget.senderId,
      quantity: _qty,
    );
    ref.refreshWalletCache(force: true);
    if (mounted) widget.onClose();
  }
}

class _GiftsTab extends StatelessWidget {
  const _GiftsTab({
    required this.gifts,
    required this.category,
    required this.onCategory,
    required this.selected,
    required this.qty,
    required this.sending,
    required this.onSelect,
    required this.onQty,
    required this.onSend,
  });

  final AsyncValue<List<GiftEntity>> gifts;
  final String category;
  final ValueChanged<String> onCategory;
  final LiveVideoGiftType? selected;
  final int qty;
  final bool sending;
  final ValueChanged<LiveVideoGiftType> onSelect;
  final ValueChanged<int> onQty;
  final VoidCallback onSend;

  List<GiftEntity> _filter(List<GiftEntity> all) {
    bool isFortune(GiftEntity g) {
      final n = g.name.toLowerCase();
      return n.contains('fal') || n.contains('tarot') || n.contains('kristal');
    }

    bool isVip(GiftEntity g) =>
        g.rarity.index >= GiftRarity.epic.index || g.price >= 200;

    return switch (category) {
      'fortune' => all.where(isFortune).toList(),
      'vip' => all.where(isVip).toList(),
      'event' => all
          .where((g) => !isFortune(g) && !isVip(g))
          .where((g) => !PremiumGiftCatalog2026.giftIds.contains(g.id))
          .toList(),
      _ => PremiumGiftCatalog2026.sortCatalog(all, (g) => g.id),
    };
  }

  @override
  Widget build(BuildContext context) {
    return gifts.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppThemeColors.accentPink),
      ),
      error: (_, _) => const Center(child: Text('Hediyeler yüklenemedi')),
      data: (catalog) {
        final mobile = catalog
            .where((g) => g.platform != GiftPlatform.web)
            .toList();
        final filtered = _filter(mobile);

        if (selected == null && filtered.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onSelect(LiveVideoGiftType.fromGift(filtered.first));
          });
        }

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  for (final c in const [
                    ('popular', 'Popüler'),
                    ('fortune', 'Fal'),
                    ('vip', 'VIP'),
                    ('event', 'Etkinlik'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.$2),
                        selected: category == c.$1,
                        onSelected: (_) => onCategory(c.$1),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                cacheExtent: 400, scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final entity = filtered[i];
                  final gift = LiveVideoGiftType.fromGift(entity);
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _PremiumGiftTile(
                      gift: gift,
                      selected: selected?.id == gift.id,
                      onTap: () => onSelect(gift),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: Row(
                children: [
                  for (final q in [1, 5, 10, 99])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('x$q'),
                        selected: qty == q,
                        onSelected: (_) => onQty(q),
                        selectedColor: AppThemeColors.accentPink.withValues(alpha: 0.45),
                        backgroundColor: Colors.white10,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  const Spacer(),
                  _SendButton(loading: sending, onPressed: onSend),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PremiumGiftTile extends StatelessWidget {
  const _PremiumGiftTile({
    required this.gift,
    required this.selected,
    required this.onTap,
  });

  final LiveVideoGiftType gift;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = gift.iconUrl(Env.siteOrigin);
    final glow = gift.rarity.glowColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 220.ms,
        width: 88,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    glow.withValues(alpha: 0.45),
                    AppThemeColors.accentPurple.withValues(alpha: 0.25),
                  ],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.07),
          border: Border.all(
            color: selected ? glow : Colors.white.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppThemeColors.glowShadow(glow, blur: 18) : null,
        ),
        child: Column(
          children: [
            _RarityBadge(rarity: gift.rarity),
            const SizedBox(height: 4),
            Expanded(
              child: url.isEmpty
                  ? Text(
                      gift.rarity.index >= GiftRarity.epic.index ? '✨' : '🎁',
                      style: const TextStyle(fontSize: 34),
                    )
                  : CanlifalNetworkImage(url: url, fit: BoxFit.contain),
            ),
            Text(
              gift.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            Text(
              '${gift.price}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppThemeColors.coinGold.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});

  final GiftRarity rarity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: rarity.glowColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rarity.borderColor.withValues(alpha: 0.6)),
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: rarity.glowColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: context.colors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppThemeColors.glowShadow(AppThemeColors.coinGold, blur: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.black87),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed, required this.loading});

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          decoration: BoxDecoration(
            gradient: context.colors.brandGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppThemeColors.glowShadow(AppThemeColors.accentPink),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Gönder',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
        ),
      ),
    );
  }
}
