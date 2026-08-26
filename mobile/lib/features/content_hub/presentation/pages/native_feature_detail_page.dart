import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/native_feature_item.dart';
import '../providers/native_feature_hub_providers.dart';

/// Blog / ünlü / fan kulübü detayı — kılavuz GET uçları.
class NativeFeatureDetailPage extends ConsumerWidget {
  const NativeFeatureDetailPage({
    super.key,
    required this.kind,
    required this.id,
  });

  final NativeFeatureHubKind kind;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nativeFeatureDetailProvider((kind: kind, id: id)));
    return DiscoverSubPage(
      title: switch (kind) {
        NativeFeatureHubKind.blog => 'Yazı',
        NativeFeatureHubKind.celebrities => 'Ünlü',
        NativeFeatureHubKind.fanClub => 'Fan kulübü',
        _ => 'Detay',
      },
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('İçerik bulunamadı'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CanlifalNetworkImage(
                    url: item.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (item.subtitle.trim().isNotEmpty)
                Text(
                  item.subtitle,
                  style: TextStyle(
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              if (item.body != null && item.body!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                SelectableText(
                  item.body!,
                  style: const TextStyle(height: 1.5, fontSize: 16),
                ),
              ],
              if (kind == NativeFeatureHubKind.celebrities) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => _followCelebrity(context, ref),
                  child: const Text('Takip et'),
                ),
              ],
              if (kind == NativeFeatureHubKind.fanClub) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => _joinFanClub(context, ref),
                  child: const Text('Kulübe katıl'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _followCelebrity(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(dioProvider)
          .safePost<dynamic>(ApiEndpoints.celebrityFollow(id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Takip edildi')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
    }
  }

  Future<void> _joinFanClub(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(dioProvider)
          .safePost<dynamic>(ApiEndpoints.fanClubJoin(id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kulübe katıldınız')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
    }
  }
}
