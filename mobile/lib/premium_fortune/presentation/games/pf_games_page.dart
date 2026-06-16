import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/pf_providers.dart';
import '../../core/theme/pf_theme.dart';
import '../../domain/entities/pf_games.dart';
import '../widgets/pf_glass_card.dart';
import '../widgets/pf_section_header.dart';

final pfQuestsProvider = FutureProvider<List<PfDailyQuest>>((ref) async {
  final user = ref.watch(pfEffectiveUserProvider);
  if (user == null) return [];
  final result = await ref.read(pfGamesRepositoryProvider).getDailyQuests(user.id);
  return result.valueOrNull ?? [];
});

final pfBadgesProvider = FutureProvider<List<PfBadge>>((ref) async {
  final user = ref.watch(pfEffectiveUserProvider);
  if (user == null) return [];
  final result = await ref.read(pfGamesRepositoryProvider).getBadges(user.id);
  return result.valueOrNull ?? [];
});

class PfGamesPage extends ConsumerStatefulWidget {
  const PfGamesPage({super.key});

  @override
  ConsumerState<PfGamesPage> createState() => _PfGamesPageState();
}

class _PfGamesPageState extends ConsumerState<PfGamesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _wheelCtrl;
  bool _spinning = false;
  int? _lastReward;

  @override
  void initState() {
    super.initState();
    _wheelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _wheelCtrl.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() => _spinning = true);
    _wheelCtrl.forward(from: 0);
    final user = ref.read(pfEffectiveUserProvider);
    if (user != null) {
      final result = await ref.read(pfGamesRepositoryProvider).spinWheel(user.id);
      await _wheelCtrl.forward();
      if (mounted) {
        setState(() {
          _spinning = false;
          _lastReward = result.valueOrNull;
        });
        if (_lastReward != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$_lastReward kredi kazandınız!')),
          );
        }
      }
    }
  }

  Future<void> _watchAd() async {
    final user = ref.read(pfEffectiveUserProvider);
    if (user == null) return;
    final result =
        await ref.read(pfGamesRepositoryProvider).watchAdForCredits(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? '${result.valueOrNull} kredi kazandınız!'
              : result.failureOrNull?.message ?? 'Hata',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quests = ref.watch(pfQuestsProvider);
    final badges = ref.watch(pfBadgesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Oyunlar & Görevler')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: PfGlassCard(
              child: Column(
                children: [
                  const Text('Şans Çarkı',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 16),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 2 + Random().nextDouble()).animate(
                      CurvedAnimation(parent: _wheelCtrl, curve: Curves.easeOutCubic),
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            PfTheme.gold,
                            PfTheme.purple,
                            PfTheme.pink,
                            PfTheme.gold,
                          ],
                        ),
                      ),
                      child: const Icon(Icons.casino_rounded, size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _spinning ? null : _spin,
                    child: Text(_spinning ? 'Dönüyor...' : 'Çevir'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _watchAd,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Reklam izle — 5 kredi kazan'),
            ),
          ),
          const PfSectionHeader(title: 'Günlük Görevler'),
          quests.when(
            data: (list) => Column(
              children: list
                  .map(
                    (q) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: PfGlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              q.isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              color: q.isCompleted
                                  ? Colors.greenAccent
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(q.description,
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              '+${q.rewardCredits}',
                              style: const TextStyle(
                                color: PfTheme.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
          const PfSectionHeader(title: 'Rozetler'),
          badges.when(
            data: (list) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list
                  .map(
                    (b) => PfGlassCard(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(b.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: b.isUnlocked
                                        ? Colors.white
                                        : Colors.white38,
                                  )),
                              Text(b.description,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.white38)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
