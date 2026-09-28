import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/agency_entity.dart';
import '../providers/agency_providers.dart';
import '../widgets/agency_weekly_task_card.dart';

final agencyWeeklyTasksProvider =
    FutureProvider.autoDispose<AgencyWeeklyTasks?>(
  (ref) => ref.watch(agencyRemoteProvider).fetchTasks(),
);

/// `/ajans/weekly-tasks` — bu haftanın hedefi + son 4 hafta.
class AgencyWeeklyTasksPage extends ConsumerWidget {
  const AgencyWeeklyTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agencyWeeklyTasksProvider);
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    return Scaffold(
      backgroundColor: PlatformSocialPalette.bgTop,
      appBar: AppBar(
        title: const Text('Haftalık görevler'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(agencyWeeklyTasksProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            ...async.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => [_hint('Görevler yüklenemedi.')],
              data: (tasks) {
                if (tasks == null || tasks.current == null) {
                  return [
                    _hint('Haftalık görev yalnızca ajans üyelerine gösterilir.'),
                  ];
                }
                return [
                  const Text(
                    'Performans puanı: kazanç %50 · aktif üye %30 · yeni üye %20',
                    style: TextStyle(color: PlatformSocialPalette.textMuted),
                  ),
                  const SizedBox(height: 12),
                  const PlatformSocialSectionTitle('Bu hafta'),
                  AgencyWeeklyTaskCard(
                    task: tasks.current!,
                    jetonLabel: jetonLabel,
                  ),
                  if (tasks.past.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const PlatformSocialSectionTitle('Geçmiş haftalar'),
                    for (final t in tasks.past) ...[
                      AgencyWeeklyTaskCard(task: t, jetonLabel: jetonLabel),
                      const SizedBox(height: 10),
                    ],
                  ],
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _hint(String text) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: PlatformSocialPalette.textMuted),
        ),
      );
}
