import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/lucky_gift_entities.dart';
import '../providers/lucky_gift_providers.dart';

/// Son büyük şanslı hediye kazançları — `scope=global`.
class LuckyGiftWinsTicker extends ConsumerWidget {
  const LuckyGiftWinsTicker({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(luckyGiftGlobalFeedProvider);
    return feed.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final line = _formatLine(items.first);
        return SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF22C55E).withValues(alpha: 0.25),
                  const Color(0xFFF59E0B).withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Center(
              child: _MarqueeText(
                text: line,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatLine(LuckyGiftHistoryEntry e) {
    final user = (e.userName ?? 'Biri').trim();
    final gift = (e.giftName ?? 'Talih Kutusu').trim();
    if (e.isJackpot) {
      return '🎰 JACKPOT! $user — $gift ×${e.multiplier} → ${e.wonJetons} jeton!';
    }
    return '🍀 $user — $gift ×${e.multiplier} → ${e.wonJetons} jeton';
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final w = MediaQuery.sizeOf(context).width;
          final offset = (w + 200) * _controller.value - 100;
          return Transform.translate(
            offset: Offset(-offset, 0),
            child: Text(
              widget.text,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: widget.style.copyWith(color: AppTheme.onBackground),
            ),
          );
        },
      ),
    );
  }
}
