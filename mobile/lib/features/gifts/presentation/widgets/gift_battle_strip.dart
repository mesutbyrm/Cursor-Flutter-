import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_battle.dart';
import '../providers/gift_battle_providers.dart';

/// Koltuk altı / yayın üstü hediye savaşı şeridi — canlı skor + geri sayım.
/// Son 10 saniyede kırmızı nabız efekti; bitince kazanan banner'ı.
class GiftBattleStrip extends ConsumerWidget {
  const GiftBattleStrip({
    super.key,
    required this.context,
    required this.contextId,
  });

  final String context;
  final String contextId;

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final key = (context: context, contextId: contextId);
    final battle = ref.watch(giftBattleProvider(key));
    if (battle == null || battle.participants.isEmpty) {
      return const SizedBox.shrink();
    }
    if (battle.isEnded) return _WinnerBanner(battle: battle);
    return _ActiveBattle(battle: battle);
  }
}

class _ActiveBattle extends StatelessWidget {
  const _ActiveBattle({required this.battle});

  final GiftBattle battle;

  String get _clock {
    final s = battle.remainingSec.clamp(0, 359999);
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final last = battle.isLastCall;
    final parts = battle.participants.take(2).toList();
    final total = battle.totalScore == 0 ? 1 : battle.totalScore;

    Widget strip = Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x33FF3D77), Color(0x333D7BFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: last ? const Color(0xFFFF4D4D) : const Color(0x55FFFFFF),
          width: last ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFF7043), size: 16),
              const SizedBox(width: 6),
              Text(
                last ? 'SON $_clock!' : 'Hediye Savaşı  $_clock',
                style: TextStyle(
                  color: last ? const Color(0xFFFF6B6B) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Skor çubuğu (iki taraf).
          if (parts.length >= 2)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 18,
                child: Row(
                  children: [
                    Expanded(
                      flex: (parts[0].score.clamp(0, 1 << 30)) + 1,
                      child: Container(
                        color: const Color(0xFFFF3D77),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${_fmt(parts[0].score)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: (parts[1].score.clamp(0, 1 << 30)) + 1,
                      child: Container(
                        color: const Color(0xFF3D7BFF),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${_fmt(parts[1].score)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final p in parts)
                Flexible(
                  child: Text(
                    p.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    // Son 10 sn — hafif nabız (ölçek) efekti.
    if (last) {
      strip = TweenAnimationBuilder<double>(
        key: ValueKey(battle.remainingSec),
        tween: Tween(begin: 1.0, end: 1.04),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: strip,
      );
    }
    // total referansı kullanımda kalsın (analyzer): oran hesabı ileride.
    assert(total >= 0);
    return strip;
  }

  static String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.battle});

  final GiftBattle battle;

  @override
  Widget build(BuildContext context) {
    final winner = battle.winnerId != null
        ? battle.participants.firstWhere(
            (p) => p.participantId == battle.winnerId,
            orElse: () => battle.leader ?? battle.participants.first,
          )
        : battle.leader;
    final name = winner?.displayName ?? '—';
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x55FFD54F), Color(0x33FF7043)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xAAFFD54F), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: Color(0xFFFFD54F), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Kazanan: $name 🎉',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
