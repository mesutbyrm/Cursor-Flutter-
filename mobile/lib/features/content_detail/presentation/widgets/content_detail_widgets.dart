import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/images/canlifal_image_urls.dart';
import '../../domain/content_detail_models.dart';

/// Boş / hata durumu — metin + «Yenile».
class ContentMessage extends StatelessWidget {
  const ContentMessage({super.key, required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Yenile')),
          ],
        ),
      ),
    );
  }
}

/// Uzak kapak görseli; URL yoksa ya da yüklenemezse simge gösterir.
class ContentCover extends StatelessWidget {
  const ContentCover({
    super.key,
    required this.url,
    required this.icon,
    this.size = 56,
  });

  final String? url;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = CanlifalImageUrls.resolve(url);
    final placeholder = Container(
      width: size,
      height: size,
      color: Colors.white.withValues(alpha: 0.08),
      child: Icon(icon, color: Colors.white54),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: resolved.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: resolved,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => placeholder,
            ),
    );
  }
}

/// Blog yazısı satırı — dokununca `/blog/{slug}`.
class BlogPostTile extends StatelessWidget {
  const BlogPostTile({super.key, required this.post, this.replace = false});

  final BlogPostItem post;

  /// Detay sayfasından ilgili yazıya geçerken yığını büyütme.
  final bool replace;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (post.readTime > 0) '${post.readTime} dk okuma',
      if (post.views > 0) '${post.views} görüntülenme',
    ].join(' · ');
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ContentCover(url: post.coverImage, icon: Icons.article_rounded),
        title: Text(
          post.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: meta.isEmpty ? null : Text(meta),
        onTap: () {
          final path = '/blog/${Uri.encodeComponent(post.slug)}';
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
