import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// `GET /api/user/broadcast-history` — canlifal.com Flutter API.
class BroadcastHistoryPage extends ConsumerWidget {
  const BroadcastHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(broadcastHistoryProvider);
    final dateFmt = DateFormat('d MMM yyyy · HH:mm');

    return DiscoverSubPage(
      title: 'Yayın Geçmişi',
      subtitle: 'Bitmiş yayınlarınız',
      onRefresh: () async => ref.invalidate(broadcastHistoryProvider),
      body: history.when(
        loading: () => const DiscoverAccentLoader(),
        error: (e, _) => DiscoverEmptyState(
          icon: Icons.history_toggle_off_rounded,
          message: ApiException.userMessage(e),
          actionLabel: 'Tekrar dene',
          action: () => ref.invalidate(broadcastHistoryProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const DiscoverEmptyState(
              icon: Icons.videocam_off_outlined,
              message: 'Henüz bitmiş yayın kaydı yok.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final b = items[i];
              final when = b.endedAt ?? b.startedAt;
              return DiscoverGlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 72,
                        height: 48,
                        child: b.thumbnailUrl != null &&
                                b.thumbnailUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: b.thumbnailUrl!,
                                fit: BoxFit.cover,
                              )
                            : ColoredBox(
                                color: AppDesign.bgPurpleGlow,
                                child: Icon(
                                  Icons.live_tv_rounded,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          if (when != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              dateFmt.format(when.toLocal()),
                              style: const TextStyle(
                                color: AppDesign.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (b.viewerCount != null && b.viewerCount! > 0)
                            Text(
                              '${b.viewerCount} izleyici',
                              style: const TextStyle(
                                color: AppDesign.textMuted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (b.status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          b.status!,
                          style: const TextStyle(fontSize: 10),
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
