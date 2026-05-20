import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../providers/notifications_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsListProvider);
    final fmt = DateFormat('HH:mm');

    return DiscoverSubPage(
      title: 'Bildirimler',
      subtitle: 'Son aktiviteler ve uyarılar',
      onRefresh: () async => ref.invalidate(notificationsListProvider),
      actions: [
        DiscoverIconButton(
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(notificationsListProvider),
        ),
      ],
      body: list.when(
        loading: () => const DiscoverAccentLoader(),
        error: (e, _) => DiscoverEmptyState(
          icon: Icons.notifications_off_outlined,
          message: e.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const DiscoverEmptyState(
              icon: Icons.notifications_none_rounded,
              message: 'Henüz bildirimin yok.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final n = items[i];
              return DiscoverGlassCard(
                onTap: () async {
                  if (!n.read) {
                    await ref
                        .read(notificationsRepositoryProvider)
                        .markRead(n.id);
                    ref.invalidate(notificationsListProvider);
                  }
                },
                borderColor: n.read
                    ? null
                    : AppDesign.accentPink.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: n.read
                            ? null
                            : AppDesign.heroGradient,
                        color: n.read
                            ? Colors.white.withValues(alpha: 0.06)
                            : null,
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        size: 22,
                        color: n.read
                            ? AppDesign.textMuted
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.read
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          if (n.body != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              n.body!,
                              style: const TextStyle(
                                color: AppDesign.textMuted,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (n.createdAt != null)
                      Text(
                        fmt.format(n.createdAt!.toLocal()),
                        style: const TextStyle(
                          color: AppDesign.textMuted,
                          fontSize: 11,
                        ),
                      ),
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
