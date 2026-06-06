import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../gifts/domain/gift_rarity.dart';
import '../../../../gifts/domain/premium_gift_catalog_2026.dart';
import '../../../../gifts/presentation/widgets/premium_2026/premium_gift_icon.dart';
import '../../../../live/domain/entities/live_gift_catalog.dart';
import '../../../../live/domain/entities/live_gift_event.dart';
import '../../../../live/domain/entities/live_gift_type.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../providers/chat_room_providers.dart';
import '../voice_room_gift_sheet.dart';

/// TikTok Live — blur panel, 8 premium hediye, combo, sıralama.
class VoicePremiumGiftPanel2026 extends ConsumerStatefulWidget {
  const VoicePremiumGiftPanel2026({
    super.key,
    required this.room,
    required this.onClose,
    required this.onSent,
  });

  final VoiceRoomEntity room;
  final VoidCallback onClose;
  final void Function(LiveGiftEvent event) onSent;

  @override
  ConsumerState<VoicePremiumGiftPanel2026> createState() =>
      _VoicePremiumGiftPanel2026State();
}

enum _GiftCategory { all, popular, special, vip }

class _VoicePremiumGiftPanel2026State
    extends ConsumerState<VoicePremiumGiftPanel2026> {
  LiveVideoGiftType? _selected;
  int _qty = 1;
  bool _sending = false;
  _GiftCategory _category = _GiftCategory.all;

  List<LiveVideoGiftType> _filterGifts(List<LiveVideoGiftType> list) {
    return switch (_category) {
      _GiftCategory.popular =>
        list.where((g) => g.price >= 50 && g.price <= 2000).toList(),
      _GiftCategory.special =>
        list.where((g) {
          final r = PremiumGiftCatalog2026.rarity(g.id);
          return r == GiftRarity.epic ||
              r == GiftRarity.legendary ||
              r == GiftRarity.mythic;
        }).toList(),
      _GiftCategory.vip =>
        list.where((g) {
          final r = PremiumGiftCatalog2026.rarity(g.id);
          return g.price >= 1000 || r == GiftRarity.mythic;
        }).toList(),
      _ => list,
    };
  }

  @override
  Widget build(BuildContext context) {
    final gifts = ref.watch(voiceRoomGiftTypesProvider);
    final coins = ref.watch(coinBalanceProvider).valueOrNull ?? 0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppThemeColors.accentPink.withValues(alpha: 0.35),
                const Color(0xFF0C0C18).withValues(alpha: 0.97),
              ],
            ),
            border: Border(
              top: BorderSide(color: AppThemeColors.accentPink.withValues(alpha: 0.55)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppThemeColors.accentPurple.withValues(alpha: 0.3),
                blurRadius: 36,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hediye Gönder',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CoinChip(coins: coins),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final c in _GiftCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CategoryChip(
                          label: switch (c) {
                            _GiftCategory.all => 'Tümü',
                            _GiftCategory.popular => 'Popüler',
                            _GiftCategory.special => 'Özel',
                            _GiftCategory.vip => 'VIP',
                          },
                          selected: _category == c,
                          onTap: () => setState(() => _category = c),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: gifts.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppThemeColors.accentPink,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(ApiException.userMessage(e)),
                  ),
                  data: (list) {
                    final sorted = PremiumGiftCatalog2026.sortCatalog(
                      list,
                      (g) => g.id,
                    );
                    final filtered = _filterGifts(sorted);
                    return _GiftsTab(
                      gifts: filtered,
                      selected: _selected,
                      qty: _qty,
                      sending: _sending,
                      onSelect: (g) => setState(() => _selected = g),
                      onQty: (q) => setState(() => _qty = q),
                      onSend: () => _send(list),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 360.ms, curve: Curves.easeOutCubic);
  }

  Future<void> _send(List<LiveVideoGiftType> catalog) async {
    final g = _selected;
    if (g == null || _sending) return;
    setState(() => _sending = true);
    try {
      final user = ref.read(authControllerProvider).valueOrNull;
      final roomKey = widget.room.apiRoomKey.isNotEmpty
          ? widget.room.apiRoomKey
          : widget.room.id;
      await ref.read(chatRoomGiftsRemoteProvider).sendGift(
            roomId: roomKey,
            giftTypeId: g.id,
            quantity: _qty,
            senderName: user?.display ?? 'Sen',
            receiverName: widget.room.ownerName ?? 'Yayıncı',
            receiverId: widget.room.ownerId,
          );
      final raw = LiveGiftEvent(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        senderId: user?.id,
        senderName: user?.display ?? 'Sen',
        receiverName: widget.room.ownerName ?? 'Oda sahibi',
        giftId: g.id,
        giftName: PremiumGiftCatalog2026.displayName(
          g.id,
          fallback: LiveGiftCatalog.displayName(g),
        ),
        quantity: _qty,
        coinCost: g.price * _qty,
        timestamp: DateTime.now(),
        combo: _qty,
        rarity: PremiumGiftCatalog2026.rarity(g.id),
      );
      ref.invalidate(coinBalanceProvider);
      ref.read(voiceRoomLiveProvider(widget.room).notifier).refresh();
      if (mounted) {
        widget.onSent(raw);
        widget.onClose();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${raw.giftName} x$_qty gönderildi'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? context.colors.brandGradient : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: selected ? Colors.white : context.colors.onSurfaceMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftsTab extends StatelessWidget {
  const _GiftsTab({
    required this.gifts,
    required this.selected,
    required this.qty,
    required this.sending,
    required this.onSelect,
    required this.onQty,
    required this.onSend,
  });

  final List<LiveVideoGiftType> gifts;
  final LiveVideoGiftType? selected;
  final int qty;
  final bool sending;
  final ValueChanged<LiveVideoGiftType> onSelect;
  final ValueChanged<int> onQty;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    if (gifts.isEmpty) {
      return const Center(child: Text('Hediye listesi boş'));
    }

    final initial = selected ?? gifts.first;
    if (selected == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onSelect(initial));
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: gifts.length,
            itemBuilder: (ctx, i) {
              final g = gifts[i];
              return _PremiumGiftTile(
                gift: g,
                selected: (selected ?? initial).id == g.id,
                onTap: () => onSelect(g),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _QtyBar(
            qty: qty,
            onMinus: () => onQty(qty > 1 ? qty - 1 : 1),
            onPlus: () => onQty(qty + 1),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.paddingOf(context).bottom + 12,
          ),
          child: _SendButton(loading: sending, onPressed: onSend, fullWidth: true),
        ),
      ],
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
    final rarity = PremiumGiftCatalog2026.rarity(gift.id);
    final glow = rarity.glowColor;
    final name = PremiumGiftCatalog2026.displayName(
      gift.id,
      fallback: LiveGiftCatalog.displayName(gift),
    );
    final canonical = PremiumGiftCatalog2026.canonicalId(gift.id) ?? gift.id;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 220.ms,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    glow.withValues(alpha: 0.5),
                    AppThemeColors.accentPurple.withValues(alpha: 0.28),
                  ],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.07),
          border: Border.all(
            color: selected ? glow : Colors.white.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppThemeColors.glowShadow(glow, blur: 20) : null,
        ),
        child: Column(
          children: [
            _RarityBadge(rarity: rarity),
            const SizedBox(height: 4),
            SizedBox(
              height: 52,
              child: url.isEmpty
                  ? PremiumGiftIcon(giftId: canonical, size: 48, animate: selected)
                  : CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
            Text(
              name,
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
        ),
      ),
    );
  }
}

String _formatCoins(int n) {
  if (n >= 1000) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
  return '$n';
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
            _formatCoins(coins),
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

class _QtyBar extends StatelessWidget {
  const _QtyBar({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Colors.white54, size: 20),
          const Spacer(),
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$qty',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.onPressed,
    required this.loading,
    this.fullWidth = false,
  });

  final VoidCallback onPressed;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: context.colors.brandGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppThemeColors.glowShadow(AppThemeColors.accentPink),
          ),
          child: Center(
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
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
    return fullWidth ? btn : btn;
  }
}
