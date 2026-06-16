import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/pf_config.dart';
import '../../core/theme/pf_theme.dart';
import '../../domain/entities/pf_tarot_reading.dart';
import '../tarot/pf_tarot_view_model.dart';
import '../widgets/pf_glass_card.dart';
import '../widgets/pf_section_header.dart';

class PfTarotPage extends ConsumerWidget {
  const PfTarotPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(pfTarotViewModelProvider.notifier);
    final history = ref.watch(pfTarotViewModelProvider);
    final deck = vm.deck;
    final selected = ref.watch(pfSelectedTarotCardsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Tarot Falı')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _ModeChip(
                    label: 'Günlük',
                    icon: Icons.wb_sunny_rounded,
                    onTap: () => _read(context, ref, PfTarotMode.daily),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChip(
                    label: 'Haftalık',
                    icon: Icons.calendar_view_week_rounded,
                    onTap: () => _read(context, ref, PfTarotMode.weekly),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const PfSectionHeader(
            title: 'Kart Seçin',
            subtitle: 'En fazla 3 kart (seçili: otomatik)',
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: deck.length,
              itemBuilder: (context, i) {
                final card = deck[i];
                final isSelected = selected.contains(card.id);
                return GestureDetector(
                  onTap: () {
                    ref.read(pfTarotViewModelProvider.notifier).toggleCard(card.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [PfTheme.gold, PfTheme.purple]
                            : [PfTheme.card, PfTheme.surfaceElevated],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? PfTheme.gold : PfTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.style_rounded,
                          color: isSelected ? Colors.white : Colors.white38,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selected.isEmpty
                    ? null
                    : () => _read(context, ref, PfTarotMode.custom),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  'Yorumla (${PfConfig.tarotReadingCost} kredi)',
                ),
              ),
            ),
          ),
          const PfSectionHeader(title: 'Geçmiş'),
          history.when(
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Henüz tarot geçmişiniz yok',
                        style: TextStyle(color: Colors.white54)),
                  )
                : Column(
                    children: items
                        .map((r) => _HistoryTile(reading: r))
                        .toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }

  Future<void> _read(
    BuildContext context,
    WidgetRef ref,
    PfTarotMode mode,
  ) async {
    final result =
        await ref.read(pfTarotViewModelProvider.notifier).createReading(mode);
    if (!context.mounted) return;
    if (result.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    if (result.reading != null) {
      context.push('/premium/tarot/result', extra: result.reading);
    }
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PfGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: PfTheme.gold, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class PfTarotResultPage extends StatelessWidget {
  const PfTarotResultPage({super.key, required this.reading});

  final PfTarotReading reading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PfTheme.surface,
      appBar: AppBar(title: const Text('Tarot Yorumu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            children: reading.cards
                .map(
                  (c) => Chip(
                    label: Text(c.name),
                    backgroundColor: PfTheme.purple.withValues(alpha: 0.3),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          PfGlassCard(
            child: Text(
              reading.interpretation,
              style: TextStyle(height: 1.6, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.reading});

  final PfTarotReading reading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: PfGlassCard(
        onTap: () => context.push('/premium/tarot/result', extra: reading),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.style_rounded, color: PfTheme.purple),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reading.cards.map((c) => c.name).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
