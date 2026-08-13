import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../domain/entities/home_trend_topic_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// `GET /api/trends` — yatay trend etiket şeridi.
class HomeTrendingTopicsSection extends ConsumerWidget {
  const HomeTrendingTopicsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(homeTrendTopicsProvider);
    return topics.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '🔥',
              title: 'Trend Konular',
              actionLabel: 'Keşfet >',
              onAction: () => context.push('/shorts'),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _TopicChip(topic: items[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.topic});

  final HomeTrendTopicEntity topic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
      child: InkWell(
        onTap: () {
          final route = topic.route;
          if (route != null && route.isNotEmpty) {
            openNativeSitePath(context, route);
          } else {
            context.push('/shorts');
          }
        },
        borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
            border: Border.all(color: HomeApprovedDesign.border),
            gradient: LinearGradient(
              colors: [
                HomeApprovedDesign.pink.withValues(alpha: 0.12),
                HomeApprovedDesign.purple.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                topic.tag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: HomeApprovedDesign.textPrimary,
                ),
              ),
              if (topic.viewsLabel != null) ...[
                const SizedBox(width: 6),
                Text(
                  topic.viewsLabel!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: HomeApprovedDesign.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
