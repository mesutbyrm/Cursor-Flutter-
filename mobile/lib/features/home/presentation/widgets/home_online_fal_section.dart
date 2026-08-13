import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../domain/entities/home_online_fal_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Online fal bölümleri — `GET /api/online-fal`.
class HomeOnlineFalSection extends ConsumerWidget {
  const HomeOnlineFalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(homeOnlineFalProvider);
    return sections.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '🔮',
              title: 'Online Fal',
              actionLabel: 'Tümü >',
              onAction: () => context.push('/canli-falcilar'),
            ),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _SectionCard(section: items[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final HomeOnlineFalEntity section;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            border: Border.all(color: HomeApprovedDesign.border),
            gradient: LinearGradient(
              colors: [
                HomeApprovedDesign.purple.withValues(alpha: 0.18),
                HomeApprovedDesign.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.imageUrl != null && section.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CanlifalNetworkImage(
                    url: section.imageUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: HomeApprovedDesign.purple,
                  size: 28,
                ),
              const Spacer(),
              Text(
                section.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: HomeApprovedDesign.textPrimary,
                ),
              ),
              if (section.subtitle?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  section.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
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

  void _open(BuildContext context) {
    final route = section.route?.trim();
    if (route != null && route.isNotEmpty) {
      openNativeSitePath(context, route);
      return;
    }
    context.push('/canli-falcilar');
  }
}
