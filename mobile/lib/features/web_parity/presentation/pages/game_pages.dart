import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../providers/parity_providers.dart';
import '../widgets/parity_widgets.dart';
import '../../../games/presentation/widgets/lobby_table_actions.dart';

/// Lamba Cini: günlük 3 hak, 3 sandıktan birini seç.
class LambaCiniPage extends ConsumerStatefulWidget {
  const LambaCiniPage({super.key});

  @override
  ConsumerState<LambaCiniPage> createState() => _LambaCiniPageState();
}

class _LambaCiniPageState extends ConsumerState<LambaCiniPage> {
  bool _busy = false;
  int? _picked;
  Map<String, dynamic>? _result;

  Future<void> _play(int i) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _picked = i;
      _result = null;
    });
    try {
      final r = await ref
          .read(parityApiProvider)
          .rawPostResult(ApiEndpoints.lambaCini, {'chestIndex': i});
      setState(() => _result = r);
      ref.invalidate(parityMapProvider(ApiEndpoints.lambaCini));
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
      setState(() => _picked = null);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(parityMapProvider(ApiEndpoints.lambaCini));
    final reward = asJsonMap(_result?['reward']);
    return MockScaffold(
      title: 'Lamba Cini',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
        children: [
          ParityBox<Map<String, dynamic>>(
            value: status,
            onRetry: () => ref.invalidate(parityMapProvider(ApiEndpoints.lambaCini)),
            builder: (s) => Center(
              child: Text(
                'Kalan hak: ${asInt(s['playsRemaining'])} / ${asInt(s['dailyLimit'])}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Bir sandık seç ✨')),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      onTap: _busy ? null : () => _play(i),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _picked == i
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _picked == i && _result != null
                              ? (reward['emoji']?.toString() ?? '🎁')
                              : '🧰',
                          style: const TextStyle(fontSize: 44),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            ParityCard(
              child: Column(
                children: [
                  Text(
                    reward['label']?.toString() ?? 'Ödül',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text('Yeni bakiye: ${asInt(_result!['newBalance'])}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Oyun lobisi: istatistik, masalar, son kazananlar.
class GamesLobbyPage extends ConsumerWidget {
  const GamesLobbyPage({super.key});

  // Backend bölüm adları: `live_tables` → {tables}, `recent_winners` →
  // {winners}, `stats` → sayılar (eski `tables`/`winners` 400 dönüyordu).
  static const _sections = [
    ('live_tables', 'Masalar', 'tables'),
    ('recent_winners', 'Son kazananlar', 'winners'),
    ('stats', 'İstatistik', ''),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: _sections.length,
      child: MockScaffold(
        title: 'Oyun Lobisi',
        body: Column(
          children: [
            TabBar(tabs: [for (final s in _sections) Tab(text: s.$2)]),
            Expanded(
              child: TabBarView(
                children: [for (final s in _sections) _Section(s.$1, s.$3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section(this.section, this.listKey);
  final String section;
  final String listKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = '${ApiEndpoints.gamesLobby}?section=$section';
    final v = ref.watch(parityMapProvider(path));
    return ParityAsync<Map<String, dynamic>>(
      value: v,
      onRetry: () => ref.invalidate(parityMapProvider(path)),
      builder: (d) {
        if (listKey.isEmpty) {
          final entries = d.entries.where((e) => e.value is num || e.value is String);
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ParityCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key)),
                        Text('${e.value}',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }
        final list = asJsonList(d[listKey]);
        if (list.isEmpty) {
          return const ParityMessage(
            icon: Icons.sports_esports_outlined,
            text: 'Şu an kayıt yok',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(parityMapProvider(path)),
          child: ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = list[i];
              final title = (e['gameType'] ?? e['game'] ?? 'Oyun').toString();
              final names = [
                e['player1Name'] ?? e['winnerName'] ?? e['winner'],
                e['player2Name'],
              ].where((x) => x != null && '$x'.isNotEmpty).join(' vs ');
              final bet = asInt(e['betAmount'] ?? e['amount']);
              final table = listKey == 'tables' ? LobbyTable.fromJson(e) : null;
              return ParityCard(
                onTap: table == null || table.id.isEmpty
                    ? null
                    : () => openLobbyTable(context, ref, table),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (names.isNotEmpty) Text(names),
                        ],
                      ),
                    ),
                    if (bet > 0) Text('$bet'),
                    if (table != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        table.isWaiting ? 'Katıl' : 'İzle',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
