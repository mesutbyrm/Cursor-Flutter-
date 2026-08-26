import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../platform/data/models/platform_popup.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';

/// Site duyurusu — `GET /api/popups`, yoksa kılavuz `GET /api/announcements`.
class HomePromoPopupBanner extends ConsumerWidget {
  const HomePromoPopupBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popups = ref.watch(homePopupsProvider);
    final announcements = ref.watch(homeAnnouncementsProvider);
    return popups.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => announcements.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (items) => _bannerFrom(context, items),
      ),
      data: (items) {
        if (items.isNotEmpty) return _bannerFrom(context, items);
        return announcements.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (fallback) => _bannerFrom(context, fallback),
        );
      },
    );
  }

  Widget _bannerFrom(BuildContext context, List<PlatformPopup> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final popup = items.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        0,
        HomeApprovedDesign.hPad,
        8,
      ),
      child: _PromoCard(
        popup: popup,
        onOpenAll: items.length > 1
            ? () => openNativeSitePath(context, '/duyurular')
            : null,
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.popup, this.onOpenAll});

  final PlatformPopup popup;
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context) {
    final image = popup.imageUrl?.trim();
    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final url = popup.actionUrl?.trim();
          if (url != null && url.isNotEmpty) {
            openNativeSitePath(context, url);
            return;
          }
          if (onOpenAll != null) {
            onOpenAll!();
            return;
          }
          openNativeSitePath(context, '/duyurular');
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: HomeApprovedDesign.border),
            gradient: LinearGradient(
              colors: [
                HomeApprovedDesign.purple.withValues(alpha: 0.2),
                HomeApprovedDesign.pink.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Row(
            children: [
              if (image != null && image.isNotEmpty)
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CanlifalNetworkImage(url: image, fit: BoxFit.cover),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        popup.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: HomeApprovedDesign.textPrimary,
                        ),
                      ),
                      if (popup.message?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          popup.message!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: HomeApprovedDesign.textSecondary,
                          ),
                        ),
                      ],
                      if (popup.actionLabel?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          popup.actionLabel!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: HomeApprovedDesign.purple,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: HomeApprovedDesign.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
