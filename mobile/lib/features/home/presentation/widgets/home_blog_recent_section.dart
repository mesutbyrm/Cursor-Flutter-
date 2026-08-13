import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../domain/entities/home_blog_post_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// `GET /api/blog/recent` — son blog yazıları yatay şerit.
class HomeBlogRecentSection extends ConsumerWidget {
  const HomeBlogRecentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(homeBlogRecentProvider);
    return posts.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '📚',
              title: 'Blog',
              actionLabel: 'Tümü >',
              onAction: () => openNativeSitePath(context, '/blog-hub'),
            ),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _BlogCard(post: items[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.post});

  final HomeBlogPostEntity post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openNativeSitePath(context, post.route),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: HomeApprovedDesign.surface,
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          border: Border.all(color: HomeApprovedDesign.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              SizedBox(
                width: 72,
                height: double.infinity,
                child: CanlifalNetworkImage(
                  url: post.imageUrl!,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 72,
                color: HomeApprovedDesign.purple.withValues(alpha: 0.15),
                child: Icon(
                  Icons.article_rounded,
                  color: HomeApprovedDesign.purple.withValues(alpha: 0.8),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: HomeApprovedDesign.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    if (post.excerpt != null && post.excerpt!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.excerpt!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: HomeApprovedDesign.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
