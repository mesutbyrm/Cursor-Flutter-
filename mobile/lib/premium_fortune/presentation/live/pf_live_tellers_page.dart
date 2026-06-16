import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/pf_providers.dart';
import '../../core/theme/pf_theme.dart';
import '../../domain/entities/pf_fortune_teller.dart';
import '../widgets/pf_glass_card.dart';
import '../widgets/pf_section_header.dart';

final pfTellersProvider = FutureProvider<List<PfFortuneTeller>>((ref) async {
  final result = await ref.read(pfLiveTellerRepositoryProvider).getTellers();
  return result.valueOrNull ?? [];
});

class PfLiveTellersPage extends ConsumerWidget {
  const PfLiveTellersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tellers = ref.watch(pfTellersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Canlı Falcılar')),
      body: tellers.when(
        data: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            const PfSectionHeader(
              title: 'Online Falcılar',
              subtitle: 'Sesli & görüntülü görüşme',
            ),
            ...list.map((t) => _TellerCard(teller: t)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

final pfTellerDetailProvider =
    FutureProvider.family<PfFortuneTeller?, String>((ref, tellerId) async {
  final result =
      await ref.read(pfLiveTellerRepositoryProvider).getTeller(tellerId);
  return result.valueOrNull;
});

class PfTellerDetailPage extends ConsumerWidget {
  const PfTellerDetailPage({super.key, required this.tellerId});

  final String tellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tellerAsync = ref.watch(pfTellerDetailProvider(tellerId));

    return Scaffold(
      backgroundColor: PfTheme.surface,
      appBar: AppBar(title: const Text('Falcı Profili')),
      body: tellerAsync.when(
        data: (teller) {
          if (teller == null) {
            return const Center(child: Text('Falcı bulunamadı'));
          }
          return _TellerDetailBody(teller: teller);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _TellerDetailBody extends ConsumerWidget {
  const _TellerDetailBody({required this.teller});

  final PfFortuneTeller teller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(pfEffectiveUserProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PfGlassCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: PfTheme.purple,
                child: Text(
                  teller.name[0],
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    teller.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (teller.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: PfTheme.gold, size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: PfTheme.gold, size: 16),
                  Text(' ${teller.rating} (${teller.reviewCount})'),
                  const SizedBox(width: 12),
                  _StatusDot(status: teller.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(teller.bio, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: teller.specialties
                    .map((s) => Chip(label: Text(s)))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text(
                '${teller.pricePerMinute} kredi / dakika',
                style: const TextStyle(color: PfTheme.gold, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: user == null
                    ? null
                    : () async {
                        final repo = ref.read(pfLiveTellerRepositoryProvider);
                        final result = await repo.startVoiceCall(user.id, teller.id);
                        if (!context.mounted) return;
                        final room = result.valueOrNull;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              room != null
                                  ? 'Sesli görüşme başlatılıyor: $room'
                                  : result.failureOrNull?.message ?? 'Hata',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.mic_rounded),
                label: const Text('Sesli'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: user == null
                    ? null
                    : () async {
                        final repo = ref.read(pfLiveTellerRepositoryProvider);
                        final result = await repo.startVideoCall(user.id, teller.id);
                        if (!context.mounted) return;
                        final room = result.valueOrNull;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              room != null
                                  ? 'Görüntülü görüşme başlatılıyor: $room'
                                  : result.failureOrNull?.message ?? 'Hata',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.videocam_rounded),
                label: const Text('Görüntülü'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: user == null
              ? null
              : () async {
                  final repo = ref.read(pfLiveTellerRepositoryProvider);
                  final result = await repo.bookAppointment(
                    userId: user.id,
                    tellerId: teller.id,
                    scheduledAt: DateTime.now().add(const Duration(hours: 2)),
                    durationMinutes: 30,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result.isSuccess
                            ? 'Randevu alındı!'
                            : result.failureOrNull?.message ?? 'Hata',
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.calendar_month_rounded),
          label: const Text('Randevu Al'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.push('/premium/chat'),
          icon: const Icon(Icons.chat_rounded),
          label: const Text('Mesaj Gönder'),
        ),
      ],
    );
  }
}

class _TellerCard extends StatelessWidget {
  const _TellerCard({required this.teller});

  final PfFortuneTeller teller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: PfGlassCard(
        onTap: () => context.push('/premium/live/${teller.id}'),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: PfTheme.purple.withValues(alpha: 0.5),
                  child: Text(
                    teller.name[0],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _StatusDot(status: teller.status, small: true),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(teller.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    teller.specialties.join(' · '),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: PfTheme.gold, size: 14),
                      Text(' ${teller.rating}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(
                        '${teller.pricePerMinute} kr/dk',
                        style: const TextStyle(
                          color: PfTheme.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status, this.small = false});

  final PfTellerStatus status;
  final bool small;

  Color get _color => switch (status) {
        PfTellerStatus.online => Colors.greenAccent,
        PfTellerStatus.busy => Colors.orangeAccent,
        PfTellerStatus.offline => Colors.white38,
      };

  String get _label => switch (status) {
        PfTellerStatus.online => 'Online',
        PfTellerStatus.busy => 'Meşgul',
        PfTellerStatus.offline => 'Offline',
      };

  @override
  Widget build(BuildContext context) {
    if (small) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: _color,
          shape: BoxShape.circle,
          border: Border.all(color: PfTheme.surface, width: 2),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(_label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
