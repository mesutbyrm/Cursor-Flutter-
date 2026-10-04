import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../providers/parity_providers.dart';
import '../widgets/parity_widgets.dart';

/// Ajans büyüme paneli (sahip/yönetici).
class AgencyGrowthPage extends ConsumerWidget {
  const AgencyGrowthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(parityMapProvider(ApiEndpoints.agencyGrowth));
    return MockScaffold(
      title: 'Ajans Büyümesi',
      body: ParityAsync<Map<String, dynamic>>(
        value: v,
        onRetry: () => ref.invalidate(parityMapProvider(ApiEndpoints.agencyGrowth)),
        builder: (d) {
          final m = asJsonMap(d['thisMonth']);
          final top = asJsonList(d['topPerformers']);
          final need = asJsonList(d['needsImprovement']);
          final agency = asJsonMap(d['agency']);
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(parityMapProvider(ApiEndpoints.agencyGrowth)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
              children: [
                ParityCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agency['name']?.toString() ?? 'Ajans',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ParityChip('Performans ${d['performance'] ?? 0}'),
                          ParityChip('Büyüme %${d['growthRate'] ?? 0}'),
                          ParityChip('Bonus %${agency['bonusRate'] ?? 0}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ParityCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ParityChip('${asInt(m['streamMinutes'])} dk yayın'),
                      ParityChip('${asInt(m['activeBroadcasters'])} aktif yayıncı'),
                      ParityChip('+${asInt(m['newMembers'])} yeni üye'),
                      ParityChip('-${asInt(m['leftMembers'])} ayrılan'),
                      ParityChip('${asInt(m['earnings'])} kazanç'),
                    ],
                  ),
                ),
                if (top.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('En iyiler',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  for (final p in top) _MemberRow(p),
                ],
                if (need.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Gelişmesi gerekenler',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  for (final p in need) _MemberRow(p),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow(this.p);
  final Map<String, dynamic> p;

  @override
  Widget build(BuildContext context) {
    final name = (p['name'] ?? p['username'] ?? 'Üye').toString();
    final minutes = asInt(p['streamMinutes'] ?? p['minutes']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ParityCard(
        child: Row(
          children: [
            UserAvatar(url: p['image']?.toString(), radius: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('$minutes dk'),
          ],
        ),
      ),
    );
  }
}

/// Başvuran kullanıcı skoru (ajans yöneticisi / admin).
class ApplicantScorePage extends ConsumerWidget {
  const ApplicantScorePage({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ApiEndpoints.agencyApplicantScore(userId);
    final v = ref.watch(parityMapProvider(path));
    return MockScaffold(
      title: 'Başvuran Skoru',
      body: ParityAsync<Map<String, dynamic>>(
        value: v,
        onRetry: () => ref.invalidate(parityMapProvider(path)),
        builder: (d) {
          final u = asJsonMap(d['user']);
          final s = asJsonMap(d['streamStats']);
          final g = asJsonMap(d['giftActivity']);
          final dims = d['dimensions'];
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
            children: [
              ParityCard(
                child: Row(
                  children: [
                    UserAvatar(url: u['image']?.toString(), radius: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['name']?.toString() ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(
                              '${asInt(u['followers'])} takipçi · hesap ${asInt(u['accountAgeDays'])} gün'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ParityCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ParityChip('${asInt(s['totalStreams'])} yayın'),
                    ParityChip('${asInt(s['totalStreamMinutes'])} dk'),
                    ParityChip('Ort. ${asInt(s['avgViewers'])} izleyici'),
                    ParityChip(
                            'Alınan hediye ${asInt(asJsonMap(g['received'])['total'])}'),
                  ],
                ),
              ),
              if (dims is Map) ...[
                const SizedBox(height: 10),
                for (final e in dims.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ParityCard(
                      child: Row(
                        children: [
                          Expanded(child: Text('${e.key}')),
                          Text('${e.value is Map ? (e.value['score'] ?? e.value['value'] ?? '') : e.value}'),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
