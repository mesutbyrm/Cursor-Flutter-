import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../domain/entities/home_page_button_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';

/// `GET /api/homepage-buttons` — banner altı hızlı erişim şeridi.
class HomeHomepageButtonsRow extends ConsumerWidget {
  const HomeHomepageButtonsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttons = ref.watch(homeHomepageButtonsProvider);
    return buttons.when(
      loading: () => const SizedBox(height: 4),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            HomeApprovedDesign.hPad,
            0,
            HomeApprovedDesign.hPad,
            8,
          ),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _ButtonChip(button: items[i]),
            ),
          ),
        );
      },
    );
  }
}

class _ButtonChip extends StatelessWidget {
  const _ButtonChip({required this.button});

  final HomePageButtonEntity button;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
      child: InkWell(
        onTap: () {
          final link = button.linkUrl?.trim();
          if (link != null && link.isNotEmpty) {
            openNativeSitePath(context, link);
          }
        },
        borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
            border: Border.all(color: HomeApprovedDesign.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (button.iconUrl != null && button.iconUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CanlifalNetworkImage(
                    url: button.iconUrl!,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: HomeApprovedDesign.purple.withValues(alpha: 0.95),
                ),
              const SizedBox(width: 6),
              Text(
                button.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: HomeApprovedDesign.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
