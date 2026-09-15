import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/util/json_util.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../providers/cfc_arena_providers.dart';

/// CFC Arena — puan/rozet odaklı yarışmalar (§21–25); ödül para/jeton değil.
class CfcArenaHubPage extends ConsumerWidget {
  const CfcArenaHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cfcArenaContestsProvider);
    return PlatformSocialScaffold(
      title: 'CFC Arena',
      subtitle: 'Rozet · unvan · görünürlük — nakit ödül değil',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => PlatformSocialEmptyState(
          icon: Icons.cloud_off_rounded,
          message: '$e',
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const PlatformSocialEmptyState(
              icon: Icons.emoji_events_outlined,
              message:
                  'Aktif yarışma yok veya sunucu henüz yarışma listesi döndürmüyor.\n'
                  'Ödüller rozet, unvan ve keşif önceliği ile verilir.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final c = rows[i];
              final name = (c['name'] ?? c['title'] ?? 'Yarışma').toString();
              final status = (c['status'] ?? c['phase'] ?? 'aktif').toString();
              final id = pick(c, ['id', 'contestId', '_id'])?.toString() ?? '';
              final type = (c['type'] ?? 'individual').toString();
              return PlatformSocialGlassCard(
                onTap: id.isEmpty ? null : () => context.push('/cfc-arena/$id'),
                gradient: LinearGradient(
                  colors: [
                    PlatformSocialPalette.accent.withValues(alpha: 0.18),
                    PlatformSocialPalette.card.withValues(alpha: 0.95),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: PlatformSocialPalette.heroGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              PlatformSocialStatusPill(
                                label: status,
                                tone: PlatformSocialPillTone.gold,
                              ),
                              PlatformSocialStatusPill(label: type),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white38),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
