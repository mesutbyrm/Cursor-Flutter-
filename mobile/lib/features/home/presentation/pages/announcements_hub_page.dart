import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../platform/data/models/platform_popup.dart';
import '../providers/home_providers.dart';

/// Site duyuruları — kılavuz `GET /api/announcements`.
class AnnouncementsHubPage extends ConsumerWidget {
  const AnnouncementsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeAnnouncementsProvider);
    return DiscoverSubPage(
      title: 'Duyurular',
      subtitle: 'Canlifal.com duyuruları',
      onRefresh: () async {
        ref.invalidate(homeAnnouncementsProvider);
        await ref.read(homeAnnouncementsProvider.future);
      },
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DiscoverEmptyState(
          icon: Icons.campaign_outlined,
          message: ApiException.userMessage(e),
          action: () => ref.invalidate(homeAnnouncementsProvider),
          actionLabel: 'Tekrar dene',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const DiscoverEmptyState(
              icon: Icons.campaign_outlined,
              message: 'Şu an duyuru yok.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AnnouncementTile(item: items[i]),
          );
        },
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item});

  final PlatformPopup item;

  @override
  Widget build(BuildContext context) {
    final image = item.imageUrl?.trim();
    return Card(
      child: ListTile(
        leading: image != null && image.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CanlifalNetworkImage(
                  url: image,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.campaign_rounded),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: item.message?.trim().isNotEmpty == true
            ? Text(
                item.message!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          final url = item.actionUrl?.trim();
          if (url != null && url.isNotEmpty) {
            openNativeSitePath(context, url);
          }
        },
      ),
    );
  }
}
