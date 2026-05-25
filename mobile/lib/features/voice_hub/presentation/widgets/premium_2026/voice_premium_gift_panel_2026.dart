import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../gifts/domain/gift_rarity.dart';
import '../../../../gifts/domain/premium_gift_catalog_2026.dart';
import '../../../../gifts/presentation/widgets/premium_2026/premium_gift_icon.dart';
import '../../../../gifts/presentation/widgets/top_gifters_leaderboard.dart';
import '../../../../live/domain/entities/live_gift_catalog.dart';
import '../../../../live/domain/entities/live_gift_event.dart';
import '../../../../live/domain/entities/live_gift_type.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_gift_leaderboard_provider.dart';
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

class _VoicePremiumGiftPanel2026State
    extends ConsumerState<VoicePremiumGiftPanel2026>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  LiveVideoGiftType? _selected;
  int _qty = 1;
  bool _sending = false;

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

  String get _receiver =>
      widget.room.ownerName?.trim().isNotEmpty == true
          ? widget.room.ownerName!.trim()
          : 'Oda sahibi';

  @override
  Widget build(BuildContext context) {
    final gifts = ref.watch(voiceRoomGiftTypesProvider);
    final leaderboard = ref.watch(voiceSessionGiftLeaderboardProvider);
    final coins = ref.watch(coinBalanceProvider).valueOrNull ?? 0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accentPink.withValues(alpha: 0.35),
                const Color(0xFF0C0C18).withValues(alpha: 0.97),
              ],
            ),
            border: Border(
              top: BorderSide(color: AppColors.accentPink.withValues(alpha: 0.55)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withValues(alpha: 0.3),
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
                            'Premium Hediyeler',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '→ $_receiver',
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.95),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                indicatorColor: AppColors.accentPink,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textMuted,
                tabs: const [
                  Tab(text: 'Hediyeler'),
                  Tab(text: 'Sıralama'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    gifts.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentPink,
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text(ApiException.userMessage(e)),
                      ),
                      data: (list) => _GiftsTab(
                        gifts: PremiumGiftCatalog2026.sortCatalog(
                          list,
                          (g) => g.id,
                        ),
                        selected: _selected,
                        qty: _qty,
                        sending: _sending,
                        onSelect: (g) => setState(() => _selected = g),
                        onQty: (q) => setState(() => _qty = q),
                        onSend: () => _send(list),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: TopGiftersLeaderboard(entries: leaderboard),
                    ),
                  ],
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
      await ref.read(chatRoomGiftsRemoteProvider).sendGift(
            roomId: widget.room.id,
            giftTypeId: g.id,
            quantity: _qty,
          );
      final user = ref.read(authControllerProvider).valueOrNull;
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
        coinCost: g.price,
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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            cacheExtent: 480,
            itemCount: gifts.length,
            itemBuilder: (ctx, i) {
              final g = gifts[i];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _PremiumGiftTile(
                  gift: g,
                  selected: (selected ?? initial).id == g.id,
                  onTap: () => onSelect(g),
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
                    selectedColor: AppColors.accentPink.withValues(alpha: 0.45),
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
        width: 92,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    glow.withValues(alpha: 0.5),
                    AppColors.accentPurple.withValues(alpha: 0.28),
                  ],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.07),
          border: Border.all(
            color: selected ? glow : Colors.white.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppColors.glowShadow(glow, blur: 20) : null,
        ),
        child: Column(
          children: [
            _RarityBadge(rarity: rarity),
            const SizedBox(height: 4),
            Expanded(
              child: url.isEmpty
                  ? PremiumGiftIcon(giftId: canonical, size: 52, animate: selected)
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
                color: AppColors.coinGold.withValues(alpha: 0.95),
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

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.coinCapsuleGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glowShadow(AppColors.coinGold, blur: 12),
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
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppColors.glowShadow(AppColors.accentPink),
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
