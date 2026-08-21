import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_goal.dart';
import '../providers/gift_goal_providers.dart';

/// Koltuk altı / yayın üstü hediye hedefi şeridi — ilerleme çubuğu + kutlama.
class GiftGoalBar extends ConsumerStatefulWidget {
  const GiftGoalBar({
    super.key,
    required this.context,
    required this.contextId,
  });

  final String context;
  final String contextId;

  @override
  ConsumerState<GiftGoalBar> createState() => _GiftGoalBarState();
}

class _GiftGoalBarState extends ConsumerState<GiftGoalBar> {
  bool _celebrating = false;

  @override
  Widget build(BuildContext context) {
    final key = (context: widget.context, contextId: widget.contextId);
    final st = ref.watch(giftGoalProvider(key));

    // Tamamlanma anını yakala → kısa kutlama efekti.
    ref.listen<GiftGoalState>(giftGoalProvider(key), (prev, next) {
      if (next.justCompleted && !_celebrating) {
        setState(() => _celebrating = true);
        ref.read(giftGoalProvider(key).notifier).acknowledgeCelebration();
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _celebrating = false);
        });
      }
    });

    final goal = st.goal;
    if (goal == null || st.dismissed) return const SizedBox.shrink();

    return _GoalStrip(
      goal: goal,
      celebrating: _celebrating,
      onDismiss: goal.isCompleted
          ? () => ref.read(giftGoalProvider(key).notifier).dismissCompleted()
          : null,
    );
  }
}

class _GoalStrip extends StatelessWidget {
  const _GoalStrip({
    required this.goal,
    required this.celebrating,
    this.onDismiss,
  });

  final GiftGoal goal;
  final bool celebrating;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final done = goal.isCompleted;
    final pct = (goal.progress * 100).round();

    final title = (goal.title.trim().isEmpty) ? 'Hediye Hedefi' : goal.title;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 2, 0, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? const Color(0xAA66E36F)
              : const Color(0xFF9C27FF).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.emoji_events_rounded : Icons.card_giftcard_rounded,
                color: done ? const Color(0xFFFFD54F) : const Color(0xFFB388FF),
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                done ? 'TAMAM' : '%$pct',
                style: TextStyle(
                  color: done ? const Color(0xFFFFD54F) : Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              if (done && onDismiss != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: goal.progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: const Color(0x33FFFFFF),
                valueColor: AlwaysStoppedAnimation<Color>(
                  done ? const Color(0xFFFFD54F) : const Color(0xFF9C27FF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_fmt(goal.currentAmount)} / ${_fmt(goal.targetAmount)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (celebrating) ...[
            const SizedBox(height: 4),
            const _CelebrationRow(),
          ],
        ],
      ),
    );
  }

  static String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}

class _CelebrationRow extends StatelessWidget {
  const _CelebrationRow();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎉', style: TextStyle(fontSize: 16)),
          SizedBox(width: 6),
          Text(
            'Hedefe ulaşıldı!',
            style: TextStyle(
              color: Color(0xFFFFD54F),
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
          SizedBox(width: 6),
          Text('🎉', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
