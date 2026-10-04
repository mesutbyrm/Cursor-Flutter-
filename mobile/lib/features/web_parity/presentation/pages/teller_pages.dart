import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../providers/parity_providers.dart';
import '../widgets/parity_widgets.dart';

/// Falcı paneli: seviye, analitik, hediyeler, doğrulama.
class TellerPanelPage extends ConsumerWidget {
  const TellerPanelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(parityMapProvider(ApiEndpoints.tellerLevel));
    final analytics = ref.watch(parityMapProvider(ApiEndpoints.tellerAnalytics));
    final gifts = ref.watch(parityListProvider(ApiEndpoints.tellerGifts));
    return MockScaffold(
      title: 'Falcı Paneli',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parityMapProvider(ApiEndpoints.tellerLevel));
          ref.invalidate(parityMapProvider(ApiEndpoints.tellerAnalytics));
          ref.invalidate(parityListProvider(ApiEndpoints.tellerGifts));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
          children: [
            ParityBox<Map<String, dynamic>>(
              value: level,
              onRetry: () =>
                  ref.invalidate(parityMapProvider(ApiEndpoints.tellerLevel)),
              builder: (d) => _LevelCard(d),
            ),
            const SizedBox(height: 12),
            ParityBox<Map<String, dynamic>>(
              value: analytics,
              onRetry: () => ref
                  .invalidate(parityMapProvider(ApiEndpoints.tellerAnalytics)),
              builder: (d) => _AnalyticsCard(d),
            ),
            const SizedBox(height: 12),
            const _SectionTitle('Haftanın hediye gönderenleri'),
            ParityBox<List<Map<String, dynamic>>>(
              value: gifts,
              onRetry: () =>
                  ref.invalidate(parityListProvider(ApiEndpoints.tellerGifts)),
              builder: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Bu hafta hediye yok'),
                  );
                }
                return Column(
                  children: [
                    for (final g in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ParityCard(
                          child: Row(
                            children: [
                              UserAvatar(
                                url: g['senderImage']?.toString(),
                                radius: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  g['senderName']?.toString() ?? 'Anonim',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${asInt(g['totalAmount'])} · ${asInt(g['giftCount'])} adet',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const _VerificationCard(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      );
}

class _LevelCard extends StatelessWidget {
  const _LevelCard(this.d);
  final Map<String, dynamic> d;

  @override
  Widget build(BuildContext context) {
    final stats = asJsonMap(d['stats']);
    final next = d['nextLevel'] is Map ? asJsonMap(d['nextLevel']) : null;
    final progress = (d['progress'] is num ? (d['progress'] as num).toDouble() : 0.0);
    final frac = (progress > 1 ? progress / 100 : progress).clamp(0.0, 1.0);
    return ParityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(d['emoji']?.toString() ?? '🔮',
                  style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['levelLabel']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('${asInt(d['points'])} puan'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: frac, minHeight: 8),
          if (next != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Sonraki: ${next['emoji']} ${next['label']} · ${asInt(next['pointsNeeded'])} puan kaldı',
                style: TextStyle(color: context.colors.onSurfaceMuted),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ParityChip('${asInt(stats['totalSessions'])} seans'),
              ParityChip('${asInt(stats['totalEarnings'])} kazanç'),
              ParityChip('⭐ ${stats['rating'] ?? 0}'),
              ParityChip('${asInt(stats['totalReviews'])} yorum'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard(this.d);
  final Map<String, dynamic> d;

  @override
  Widget build(BuildContext context) {
    final s = asJsonMap(d['summary']);
    final tips = (d['tips'] is List) ? (d['tips'] as List).map((e) => '$e').toList() : <String>[];
    final hours = asJsonList(d['bestHours']);
    final daily = asJsonList(d['dailySessions']);
    final maxCount = daily.fold<int>(1, (m, e) => asInt(e['count']) > m ? asInt(e['count']) : m);
    return ParityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Analitik (30 gün)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ParityChip('${asInt(s['totalSessions30d'])} seans'),
              ParityChip('${asInt(s['totalEarnings30d'])} kazanç'),
              ParityChip('Ort. ${s['avgDuration'] ?? 0} dk'),
              ParityChip('⭐ ${s['avgRating'] ?? 0}'),
              ParityChip('Bu hafta ${asInt(s['thisWeekSessions'])} seans'),
              ParityChip('Bu hafta ${asInt(s['thisWeekEarnings'])} kazanç'),
            ],
          ),
          if (daily.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final e in daily)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                          height: 8 + 64 * asInt(e['count']) / maxCount,
                          decoration: BoxDecoration(
                            color: context.accentPurple,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (hours.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'En yoğun saatler: ${hours.take(3).map((h) => '${asInt(h['hour'])}:00').join(' · ')}',
            ),
          ],
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('💡 $t'),
            ),
        ],
      ),
    );
  }
}

class _VerificationCard extends ConsumerStatefulWidget {
  const _VerificationCard();

  @override
  ConsumerState<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends ConsumerState<_VerificationCard> {
  final _url = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(parityApiProvider)
          .rawPost(ApiEndpoints.tellerVerification, {'docUrl': url});
      ref.invalidate(parityMapProvider(ApiEndpoints.tellerVerification));
      _url.clear();
      if (mounted) parityToast(context, 'Belge gönderildi, inceleniyor');
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(parityMapProvider(ApiEndpoints.tellerVerification));
    return ParityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Doğrulama'),
          ParityBox<Map<String, dynamic>>(
            value: v,
            onRetry: () => ref
                .invalidate(parityMapProvider(ApiEndpoints.tellerVerification)),
            builder: (d) {
              final status = d['verificationStatus']?.toString() ?? 'none';
              final label = switch (status) {
                'approved' => 'Onaylandı ✅',
                'pending' => 'İnceleniyor ⏳',
                'rejected' => 'Reddedildi ❌',
                _ => 'Belge gönderilmedi',
              };
              final note = d['verificationNote']?.toString();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (note != null && note.isNotEmpty) Text(note),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Belge bağlantısı (URL)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _busy ? null : _send,
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gönder'),
            ),
          ),
        ],
      ),
    );
  }
}
