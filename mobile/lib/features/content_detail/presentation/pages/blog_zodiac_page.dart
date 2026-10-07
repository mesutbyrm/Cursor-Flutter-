import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../data/content_detail_remote_datasource.dart';
import '../../domain/content_detail_models.dart';
import '../widgets/content_detail_widgets.dart';

/// Burç yazıları — `GET /api/blog/zodiac` (burç başına sayı) ve
/// `GET /api/blog/zodiac?sign=` (seçili burcun yazıları).
class BlogZodiacPage extends ConsumerStatefulWidget {
  const BlogZodiacPage({super.key, this.initialSign});

  final String? initialSign;

  @override
  ConsumerState<BlogZodiacPage> createState() => _BlogZodiacPageState();
}

class _BlogZodiacPageState extends ConsumerState<BlogZodiacPage> {
  late String _sign = ZodiacBlogSign.labels.containsKey(widget.initialSign)
      ? widget.initialSign!
      : ZodiacBlogSign.labels.keys.first;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final s in ref.watch(blogZodiacSignsProvider).valueOrNull ??
          const <ZodiacBlogSign>[])
        s.sign: s.totalPosts,
    };
    final posts = ref.watch(blogZodiacPostsProvider(_sign));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Burç Yazıları',
          subtitle: ZodiacBlogSign.labels[_sign],
          body: Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final e in ZodiacBlogSign.labels.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            (counts[e.key] ?? 0) > 0
                                ? '${e.value} (${counts[e.key]})'
                                : e.value,
                          ),
                          selected: e.key == _sign,
                          onSelected: (_) => setState(() => _sign = e.key),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: posts.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ContentMessage(
                    text: ApiException.userMessage(e),
                    onRetry: () =>
                        ref.invalidate(blogZodiacPostsProvider(_sign)),
                  ),
                  data: (items) => items.isEmpty
                      ? ContentMessage(
                          text:
                              '${ZodiacBlogSign.labels[_sign]} için henüz yazı yok.',
                          onRetry: () =>
                              ref.invalidate(blogZodiacPostsProvider(_sign)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) =>
                              BlogPostTile(post: items[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
