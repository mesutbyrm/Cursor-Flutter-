import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/dark_lane_theme.dart';
import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/network/api_exception.dart';
import '../../../live/domain/entities/live_gift_type.dart';
import '../../../live/presentation/gifts/live_gift_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/premium_gift_catalog_2026.dart';
import '../../domain/gift_animation_kind.dart';
import '../../domain/gift_entity.dart';
import '../../domain/gift_platform.dart';
import '../../domain/gift_rarity.dart';
import '../providers/gift_providers.dart';
import 'top_gifters_leaderboard.dart';
import '../../../gift_box/presentation/widgets/gift_box_panel_section.dart';

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

class _PremiumGiftPanelState extends ConsumerState<PremiumGiftPanel> {
  LiveVideoGiftType? _selected;
  int _qty = 1;
  String _category = 'popular';

  static const _tabs = [
    ('popular', 'Hediyeler'),
    ('special', 'Özel'),
    ('vip', 'Lüks'),
    ('animation', 'Animasyon'),
    ('gift_box', 'Kutu'),
    ('supporters', 'Destekçiler'),
  ];

  @override
  Widget build(BuildContext context) {
    final gifts = ref.watch(liveGiftCatalogProvider);
    // Bakiye bilinmiyorsa "0" değil "—" gösterilir.
    final coins =
        widget.controller.coinBalance ?? ref.watch(coinBalanceProvider);

    // Panel her temada koyu zemin çizer; içindeki metin/çip/sekme renkleri de
    // koyu temadan gelsin (açık temada okunmuyordu).
    return DarkLaneTheme(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.56,
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
                top: BorderSide(
                  color: AppThemeColors.accentPink.withValues(alpha: 0.5),
                ),
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
                  padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _CoinChip(coins: coins),
                      IconButton(
                        onPressed: widget.onClose,
                        tooltip: 'Kapat',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _TabRow(
                    tabs: _tabs,
                    current: _category,
                    onChanged: (c) => setState(() => _category = c),
                  ),
                ),
                Expanded(
                  child: _category == 'supporters'
                      ? ref
                            .watch(streamGiftLeaderboardProvider(widget.streamId))
                            .when(
                              loading: () => const TopGiftersLeaderboard(
                                entries: [],
                                loading: true,
                              ),
                              error: (_, _) =>
                                  const TopGiftersLeaderboard(entries: []),
                              data: (list) => SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: TopGiftersLeaderboard(entries: list),
                              ),
                            )
                      : _GiftsTab(
                          gifts: gifts,
                          streamId: widget.streamId,
                          category: _category,
                          coins: coins,
                          selected: _selected,
                          qty: _qty,
                          sending: widget.controller.sending,
                          onSelect: (g) => setState(() => _selected = g),
                          onQty: (q) => setState(() => _qty = q.clamp(1, 99)),
                          onSend: _send,
                          onBuy: () => openJetonStore(context, ref: ref),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      duration: 340.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _send() async {
    final g = _selected;
    if (g == null) return;
    widget.onClose();
    unawaited(_sendAsync(g));
  }

  Future<void> _sendAsync(LiveVideoGiftType g) async {
    try {
      await widget.controller.send(
        gift: g,
        senderName: widget.senderName,
        senderId: widget.senderId,
        quantity: _qty,
      );
      ref.refreshWalletCache(force: true);
    } catch (e) {
      if (!mounted) return;
      showJetonAwareError(context, ApiException.userMessage(e), ref: ref);
    }
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.tabs,
    required this.current,
    required this.onChanged,
  });

  final List<(String, String)> tabs;
  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in tabs)
            InkWell(
              onTap: () => onChanged(t.$1),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.$2,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: current == t.$1
                            ? Colors.white
                            : Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 2.5,
                      width: current == t.$1 ? 22 : 0,
                      decoration: BoxDecoration(
                        color: AppThemeColors.accentPink,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GiftsTab extends StatelessWidget {
  const _GiftsTab({
    required this.gifts,
    required this.streamId,
    required this.category,
    required this.coins,
    required this.selected,
    required this.qty,
    required this.sending,
    required this.onSelect,
    required this.onQty,
    required this.onSend,
    required this.onBuy,
  });

  final AsyncValue<List<GiftEntity>> gifts;
  final String streamId;
  final String category;
  final int? coins;
  final LiveVideoGiftType? selected;
  final int qty;
  final bool sending;
  final ValueChanged<LiveVideoGiftType> onSelect;
  final ValueChanged<int> onQty;
  final VoidCallback onSend;
  final VoidCallback onBuy;

  List<GiftEntity> _filter(List<GiftEntity> all) {
    bool isFortune(GiftEntity g) {
      final n = g.name.toLowerCase();
      return n.contains('fal') || n.contains('tarot') || n.contains('kristal');
    }

    bool isVip(GiftEntity g) =>
        g.rarity.index >= GiftRarity.epic.index || g.price >= 200;

    return switch (category) {
      'special' => all.where((g) => !isVip(g) && isFortune(g)).toList(),
      'vip' => all.where(isVip).toList(),
      'animation' => all
          .where(
            (g) =>
                g.animationKind != GiftAnimationKind.none &&
                (g.animationRef?.isNotEmpty ?? false),
          )
          .toList(),
      _ => PremiumGiftCatalog2026.sortCatalog(all, (g) => g.id),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (category == 'gift_box') {
      return GiftBoxPanelSection(scope: (roomId: null, streamId: streamId));
    }
    return gifts.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppThemeColors.accentPink,
        ),
      ),
      error: (_, _) => const Center(child: Text('Hediyeler yüklenemedi')),
      data: (catalog) {
        final mobile = catalog
            .where((g) => g.platform != GiftPlatform.web)
            .toList();
        final filtered = _filter(mobile);
        // Seçim görünen listede değilse (sekme değişti) ilk hediyeye geç;
        // eskiden "Gönder" başka sekmede kalan görünmez hediyeyi yolluyordu.
        LiveVideoGiftType? current;
        for (final g in filtered) {
          if (g.id == selected?.id) {
            current = LiveVideoGiftType.fromGift(g);
            break;
          }
        }
        if (current == null && filtered.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onSelect(LiveVideoGiftType.fromGift(filtered.first));
          });
        }
        final total = current == null ? null : current.price * qty;
        final insufficient =
            total != null && coins != null && total > coins!;

        return Column(
          children: [
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Bu kategoride hediye yok',
                        style: TextStyle(color: context.colors.onSurfaceMuted),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final gift = LiveVideoGiftType.fromGift(filtered[i]);
                        return _PremiumGiftTile(
                          gift: gift,
                          selected: current?.id == gift.id,
                          onTap: () => onSelect(gift),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.paddingOf(context).bottom + 10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyStepper(qty: qty, onQty: onQty),
                  const SizedBox(height: 8),
                  if (insufficient)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Yeterli Jetonunuz yok',
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: insufficient
                        ? _BuyButton(onPressed: onBuy)
                        : _SendButton(
                            loading: sending,
                            total: total,
                            onPressed: current == null ? null : onSend,
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.qty, required this.onQty});

  final int qty;
  final ValueChanged<int> onQty;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, bool enabled, VoidCallback onTap, String label) =>
        Semantics(
          button: true,
          label: label,
          child: IconButton(
            onPressed: enabled ? onTap : null,
            icon: Icon(icon),
            color: Colors.white,
            disabledColor: Colors.white24,
            visualDensity: VisualDensity.compact,
          ),
        );
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          btn(Icons.remove_rounded, qty > 1, () => onQty(qty - 1), 'Azalt'),
          Expanded(
            child: Center(
              child: Text(
                'x$qty',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          btn(Icons.add_rounded, qty < 99, () => onQty(qty + 1), 'Artır'),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: AppThemeColors.coinGold,
          ),
          child: const Center(
            child: Text(
              'Jeton Al',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
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

    return Semantics(
      button: true,
      selected: selected,
      label: '${gift.name}, ${gift.price} jeton',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? AppThemeColors.accentPink.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: selected
                  ? AppThemeColors.accentPink
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? AppThemeColors.glowShadow(glow, blur: 14)
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: url.isEmpty
                    ? Center(
                        child: Text(
                          gift.rarity.index >= GiftRarity.epic.index
                              ? '✨'
                              : '🎁',
                          style: const TextStyle(fontSize: 34),
                        ),
                      )
                    : CanlifalNetworkImage(url: url, fit: BoxFit.contain),
              ),
              const SizedBox(height: 4),
              Text(
                gift.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    size: 11,
                    color: AppThemeColors.coinGold,
                  ),
                  const SizedBox(width: 2),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});
  final int? coins;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: coins == null ? 'Bakiye yükleniyor' : 'Bakiye $coins jeton',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: context.colors.brandGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppThemeColors.glowShadow(
            AppThemeColors.coinGold,
            blur: 12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on_rounded,
              size: 16,
              color: Colors.black87,
            ),
            const SizedBox(width: 4),
            Text(
              coins == null ? '—' : '$coins',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.onPressed,
    required this.loading,
    this.total,
  });

  /// null → gönderilecek hediye yok (buton pasif).
  final VoidCallback? onPressed;
  final bool loading;

  /// Seçili hediye × adet toplam jeton.
  final int? total;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: total == null ? 'Gönder' : 'Gönder, $total jeton',
      excludeSemantics: true,
      onTap: enabled ? onPressed : null,
      child: Opacity(
        opacity: enabled || loading ? 1 : 0.45,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: context.colors.brandGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: enabled
                    ? AppThemeColors.glowShadow(AppThemeColors.accentPink)
                    : null,
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
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Gönder',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        if (total != null) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.monetization_on_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
