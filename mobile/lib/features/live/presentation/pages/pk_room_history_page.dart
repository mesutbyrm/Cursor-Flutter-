import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pk/pk_room_models.dart';
import '../providers/pk_room_providers.dart';

/// PK geçmişi — galibiyet/mağlubiyet/berabere, mod, skor, jeton, süre.
class PkRoomHistoryPage extends ConsumerWidget {
  const PkRoomHistoryPage({super.key});

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pkHistoryProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('PK Geçmişi'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Geçmiş yüklenemedi.',
              style: TextStyle(color: Color(0x99FFFFFF))),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
              child: Text('Henüz PK yapılmamış.',
                  style: TextStyle(color: Color(0x99FFFFFF))),
            );
          }
          final wins = rows.where((r) => r.isWin).length;
          final losses = rows.where((r) => r.isLoss).length;
          final draws = rows.where((r) => r.isDraw).length;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pkHistoryProvider),
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                Row(
                  children: [
                    _Tally('Galibiyet', wins, const Color(0xFF66E36F)),
                    const SizedBox(width: 8),
                    _Tally('Mağlubiyet', losses, const Color(0xFFFF6E6E)),
                    const SizedBox(width: 8),
                    _Tally('Berabere', draws, const Color(0xFFB0BEC5)),
                  ],
                ),
                const SizedBox(height: 16),
                for (final r in rows) _HistoryRow(entry: r, fmt: _fmt),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1030),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 20)),
            Text(label,
                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.fmt});
  final PkHistoryEntry entry;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final (label, color) = entry.isWin
        ? ('Galibiyet', const Color(0xFF66E36F))
        : entry.isLoss
            ? ('Mağlubiyet', const Color(0xFFFF6E6E))
            : ('Berabere', const Color(0xFFB0BEC5));
    final modeLabel = switch (entry.mode) {
      PkRoomMode.team => 'Takım',
      PkRoomMode.guest => 'Çoklu',
      PkRoomMode.oneVsOne => '1v1',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.opponentName != null && entry.opponentName!.isNotEmpty
                      ? 'vs ${entry.opponentName}'
                      : '$modeLabel PK',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  '$modeLabel · ${entry.myScore}–${entry.opponentScore}',
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (entry.coins > 0)
            Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: Color(0xFFFFD54F), size: 14),
                const SizedBox(width: 3),
                Text(fmt(entry.coins),
                    style: const TextStyle(
                        color: Color(0xFFFFE082),
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }
}
