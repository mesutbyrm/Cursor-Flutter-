import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../domain/gift_mission.dart';
import '../../domain/gift_sender_map.dart';
import '../providers/gift_insights_providers.dart';

/// Hediye Merkezi — günlük görevler, bana özel öneriler, gönderen haritası.
class GiftHubPage extends ConsumerWidget {
  const GiftHubPage({super.key});

  static const _mapKey = (period: 'weekly', scope: 'tr');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(giftMissionsProvider);
    final recs = ref.watch(giftRecommendationsProvider(null));
    final map = ref.watch(giftSenderMapProvider(_mapKey));

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('Hediye Merkezi'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(giftMissionsProvider);
          ref.invalidate(giftRecommendationsProvider(null));
          ref.invalidate(giftSenderMapProvider(_mapKey));
        },
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            const _SectionTitle('Günlük Görevler', icon: Icons.task_alt_rounded),
            const SizedBox(height: 8),
            missions.when(
              data: (list) => list.isEmpty
                  ? const _Empty('Aktif görev yok.')
                  : Column(
                      children: [for (final m in list) _MissionCard(mission: m)],
                    ),
              loading: () => const _Loading(),
              error: (_, __) => const _Empty('Görevler yüklenemedi.'),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Sana Özel Öneriler',
                icon: Icons.auto_awesome_rounded),
            const SizedBox(height: 8),
            recs.when(
              data: (list) => list.isEmpty
                  ? const _Empty('Şimdilik öneri yok.')
                  : SizedBox(
                      height: 128,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final r = list[i];
                          return _RecCard(
                            name: r.name,
                            iconUrl: r.iconUrl,
                            price: r.price,
                            reason: r.reason,
                          );
                        },
                      ),
                    ),
              loading: () => const _Loading(),
              error: (_, __) => const _Empty('Öneriler yüklenemedi.'),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Gönderen Haritası',
                icon: Icons.public_rounded),
            const SizedBox(height: 8),
            map.when(
              data: (m) => m.points.isEmpty
                  ? const _Empty('Henüz veri yok.')
                  : Column(
                      children: [
                        for (final p in m.points.take(20))
                          _MapRow(point: p, maxTotal: m.maxTotal),
                      ],
                    ),
              loading: () => const _Loading(),
              error: (_, __) => const _Empty('Harita yüklenemedi.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends ConsumerStatefulWidget {
  const _MissionCard({required this.mission});
  final GiftMission mission;

  @override
  ConsumerState<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends ConsumerState<_MissionCard> {
  bool _claiming = false;

  Future<void> _claim() async {
    setState(() => _claiming = true);
    try {
      await ref
          .read(giftInsightsRemoteProvider)
          .claimMission(widget.mission.id);
      ref.invalidate(giftMissionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödül alındı! 🎁')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödül alınamadı, tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: m.completed ? const Color(0x5566E36F) : const Color(0x22FFFFFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (m.reward > 0)
                Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded,
                        color: Color(0xFFFFD54F), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      m.rewardLabel ?? '${m.reward}',
                      style: const TextStyle(
                        color: Color(0xFFFFE082),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (m.description != null && m.description!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              m.description!,
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: m.progressRatio,
                    minHeight: 7,
                    backgroundColor: const Color(0x33FFFFFF),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      m.completed
                          ? const Color(0xFF66E36F)
                          : const Color(0xFFB388FF),
                    ),
                  ),
                ),
              ),
              if (m.target > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${m.progress}/${m.target}',
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          if (m.canClaim) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _claiming ? null : _claim,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF66E36F),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: _claiming
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ödülü Al',
                        style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ] else if (m.claimed)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('✓ Ödül alındı',
                  style: TextStyle(
                      color: Color(0xFF66E36F),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _RecCard extends StatelessWidget {
  const _RecCard({
    required this.name,
    required this.iconUrl,
    required this.price,
    required this.reason,
  });

  final String name;
  final String? iconUrl;
  final int price;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33B388FF)),
      ),
      child: Column(
        children: [
          Expanded(
            child: iconUrl != null && iconUrl!.isNotEmpty
                ? CanlifalNetworkImage(url: iconUrl!, fit: BoxFit.contain)
                : const Icon(Icons.card_giftcard_rounded,
                    color: Color(0xFFB388FF), size: 34),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          if (price > 0)
            Text('$price',
                style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MapRow extends StatelessWidget {
  const _MapRow({required this.point, required this.maxTotal});
  final GiftMapPoint point;
  final int maxTotal;

  static String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = maxTotal <= 0 ? 0.0 : (point.total / maxTotal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              point.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: const Color(0x22FFFFFF),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFF7043)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _fmt(point.total),
            style: const TextStyle(
              color: Color(0xFFFFE082),
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFB388FF), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(color: Color(0x99FFFFFF))),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
}
