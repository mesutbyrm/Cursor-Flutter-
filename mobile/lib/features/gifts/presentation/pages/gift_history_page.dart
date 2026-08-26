import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/gift_history_item.dart';
import '../providers/gift_insights_providers.dart';

/// Hediye geçmişim — gönderilen/alınan/iade zaman çizelgesi.
class GiftHistoryPage extends ConsumerStatefulWidget {
  const GiftHistoryPage({super.key});

  @override
  ConsumerState<GiftHistoryPage> createState() => _GiftHistoryPageState();
}

class _GiftHistoryPageState extends ConsumerState<GiftHistoryPage> {
  String _direction = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(giftHistoryProvider(_direction));
    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('Hediye Geçmişim'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Tümü')),
                ButtonSegment(value: 'sent', label: Text('Gönderilen')),
                ButtonSegment(value: 'received', label: Text('Alınan')),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
              showSelectedIcon: false,
            ),
          ),
          Expanded(
            child: async.when(
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Text('Geçmiş boş.',
                          style: TextStyle(color: Color(0x99FFFFFF))))
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(giftHistoryProvider(_direction)),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _HistoryRow(item: items[i]),
                      ),
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ApiException.userMessage(e),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0x99FFFFFF)),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(giftHistoryProvider(_direction)),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});
  final GiftHistoryItem item;

  static String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final sent = item.isSent;
    final refunded = item.isRefunded;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF2A1A45),
            backgroundImage:
                item.giftIcon != null && item.giftIcon!.isNotEmpty
                    ? canlifalImageProvider(item.giftIcon!)
                    : null,
            child: item.giftIcon == null || item.giftIcon!.isEmpty
                ? const Icon(Icons.card_giftcard_rounded,
                    color: Color(0xFFB388FF), size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.giftName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  '${sent ? 'Alıcı' : 'Gönderen'}: ${item.counterpartyName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    sent ? Icons.north_east_rounded : Icons.south_west_rounded,
                    size: 13,
                    color: sent
                        ? const Color(0xFFFF8A65)
                        : const Color(0xFF66E36F),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _fmt(item.amount),
                    style: TextStyle(
                      color: refunded
                          ? const Color(0xFF9E9E9E)
                          : (sent
                              ? const Color(0xFFFF8A65)
                              : const Color(0xFF66E36F)),
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      decoration:
                          refunded ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
              if (refunded)
                const Text('iade',
                    style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
