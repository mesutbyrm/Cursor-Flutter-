import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ContentPost>> posts = ref.watch(explorePostsProvider);
    return ResponsiveMaxWidth(
      child: CustomScrollView(
        slivers: <Widget>[
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Keşfet',
              subtitle:
                  'Hashtag, trend sistemi, kaydedilenler ve viral içerikler',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Falcı, canlı yayın, hashtag veya içerik ara',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.tune),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const <Widget>[
                  Chip(label: Text('#kahvefalı')),
                  Chip(label: Text('#tarot')),
                  Chip(label: Text('#canlıyayın')),
                  Chip(label: Text('#fanclub')),
                  Chip(label: Text('#premium')),
                ],
              ),
            ),
          ),
          posts.when(
            data: (List<ContentPost> items) {
              if (items.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Keşfet içeriği bulunamadı.')),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisExtent: 300,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final ContentPost post = items[index];
                    return GlassCard(
                      padding: EdgeInsets.zero,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: CachedNetworkImage(
                              imageUrl: post.mediaUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Colors.transparent,
                                  Colors.black87,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  post.caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.favorite,
                                      size: 16,
                                      color: Colors.pinkAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(compactNumber(post.likes)),
                                    const Spacer(),
                                    if (post.isVideo)
                                      const Icon(Icons.play_circle, size: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stackTrace) =>
                SliverToBoxAdapter(child: Center(child: Text('$error'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}
