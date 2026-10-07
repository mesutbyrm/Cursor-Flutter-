import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../data/content_detail_remote_datasource.dart';
import '../../domain/content_detail_models.dart';
import '../widgets/content_detail_widgets.dart';

/// TikTok video seçkisi — `GET /api/tiktok-videos`.
class TiktokVideosPage extends ConsumerWidget {
  const TiktokVideosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tiktokVideosProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'TikTok Videoları',
          subtitle: 'Editör seçkisi',
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ContentMessage(
              text: ApiException.userMessage(e),
              onRetry: () => ref.invalidate(tiktokVideosProvider),
            ),
            data: (items) => items.isEmpty
                ? ContentMessage(
                    text: 'Henüz video eklenmemiş.',
                    onRetry: () => ref.invalidate(tiktokVideosProvider),
                  )
                : _VideoList(items: items),
          ),
        ),
      ),
    );
  }
}

/// Tek video + ilgili videolar — `GET /api/tiktok-videos/{id}`.
/// Oynatma TikTok uygulamasında/tarayıcıda (yalnız https bağlantı).
class TiktokVideoPage extends ConsumerWidget {
  const TiktokVideoPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tiktokVideoProvider(id));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: async.valueOrNull?.video.displayTitle ?? 'TikTok',
          subtitle: async.valueOrNull?.video.categoryTitle,
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ContentMessage(
              text: ApiException.userMessage(e),
              onRetry: () => ref.invalidate(tiktokVideoProvider(id)),
            ),
            data: (d) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                Center(
                  child: ContentCover(
                    url: d.video.thumbnailUrl,
                    icon: Icons.play_circle_fill_rounded,
                    size: 220,
                  ),
                ),
                const SizedBox(height: 12),
                if ((d.video.authorName ?? '').isNotEmpty)
                  Text(
                    '@${d.video.authorName}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: d.video.externalUri == null
                      ? null
                      : () => _open(context, d.video.externalUri!),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('TikTok\'ta izle'),
                ),
                if (d.related.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Benzer videolar',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final v in d.related) ...[
                    _VideoTile(video: v, replace: true),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video açılamadı')),
      );
    }
  }
}

class _VideoList extends StatelessWidget {
  const _VideoList({required this.items});

  final List<TiktokVideoItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _VideoTile(video: items[i]),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video, this.replace = false});

  final TiktokVideoItem video;
  final bool replace;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        leading: ContentCover(
          url: video.thumbnailUrl,
          icon: Icons.play_circle_fill_rounded,
        ),
        title: Text(
          video.displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: video.categoryTitle == null ? null : Text(video.categoryTitle!),
        onTap: () {
          final path = '/tiktok/${Uri.encodeComponent(video.id)}';
          if (replace) {
            context.pushReplacement(path);
          } else {
            context.push(path);
          }
        },
      ),
    );
  }
}
