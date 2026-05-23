import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../../domain/entities/live_gift_catalog.dart';
import '../../../domain/entities/live_gift_type.dart';
import '../live_gift_controller.dart';
import '../providers/live_gift_providers.dart';

class LiveGiftPanel extends ConsumerStatefulWidget {
  const LiveGiftPanel({
    super.key,
    required this.controller,
    required this.senderName,
    this.senderId,
    required this.onClose,
  });

  final LiveGiftController controller;
  final String senderName;
  final String? senderId;
  final VoidCallback onClose;

  @override
  ConsumerState<LiveGiftPanel> createState() => _LiveGiftPanelState();
}

class _LiveGiftPanelState extends ConsumerState<LiveGiftPanel> {
  LiveVideoGiftType? _selected;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final gifts = ref.watch(liveGiftTypesProvider);
    final coins = widget.controller.coinBalance ??
        ref.watch(coinBalanceProvider).valueOrNull ??
        0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.paddingOf(context).bottom + 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accentPurple.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.92),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.accentPink.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Hediye Gönder',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
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
              const SizedBox(height: 12),
              gifts.when(
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const Text('Hediyeler yüklenemedi'),
                data: (all) {
                  final featured = LiveGiftCatalog.featuredFrom(all);
                  if (_selected == null && featured.isNotEmpty) {
                    _selected = featured.first;
                  }
                  return SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) {
                        final g = featured[i];
                        final sel = _selected?.id == g.id;
                        return _GiftGlowTile(
                          gift: g,
                          selected: sel,
                          onTap: () => setState(() => _selected = g),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final q in [1, 5, 10, 99])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('x$q'),
                        selected: _qty == q,
                        onSelected: (_) => setState(() => _qty = q),
                        selectedColor: AppColors.accentPink.withValues(alpha: 0.5),
                        backgroundColor: Colors.white10,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  const Spacer(),
                  _SendGlowButton(
                    loading: widget.controller.sending,
                    onPressed: _selected == null
                        ? null
                        : () async {
                            final g = _selected!;
                            await widget.controller.send(
                              gift: g,
                              senderName: widget.senderName,
                              senderId: widget.senderId,
                              quantity: _qty,
                            );
                            ref.invalidate(coinBalanceProvider);
                            if (context.mounted) widget.onClose();
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
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

class _GiftGlowTile extends StatelessWidget {
  const _GiftGlowTile({
    required this.gift,
    required this.selected,
    required this.onTap,
  });

  final LiveVideoGiftType gift;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = LiveGiftCatalog.displayName(gift);
    final url = gift.iconUrl(Env.siteOrigin);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 220.ms,
        width: 76,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.accentPink.withValues(alpha: 0.5),
                    AppColors.accentPurple.withValues(alpha: 0.4),
                  ],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: selected
                ? AppColors.accentPink
                : Colors.white.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? AppColors.glowShadow(AppColors.accentPink, blur: 16)
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: url.isEmpty
                  ? Text(
                      LiveGiftCatalog.emojiById[gift.id] ?? '🎁',
                      style: const TextStyle(fontSize: 32),
                    )
                  : CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
            Text(
              '${gift.price}',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.coinGold.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendGlowButton extends StatelessWidget {
  const _SendGlowButton({required this.onPressed, required this.loading});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(20),
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
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
        ),
      ),
    );
  }
}

class LiveGiftSideButton extends StatelessWidget {
  const LiveGiftSideButton({super.key, required this.onTap, this.label = 'Hediye'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentPink.withValues(alpha: 0.9),
                  AppColors.accentPurple.withValues(alpha: 0.85),
                ],
              ),
              boxShadow: AppColors.glowShadow(AppColors.accentPink, blur: 20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 26),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 1800.ms, color: Colors.white24)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                duration: 1200.ms,
              ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
