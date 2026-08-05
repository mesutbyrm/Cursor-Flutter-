import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/hero_tags.dart';
import '../providers/shorts_providers.dart';
import '../widgets/shorts_premium_theme.dart';

class ShortHashtagPage extends ConsumerStatefulWidget {
  const ShortHashtagPage({super.key, required this.name});

  final String name;

  @override
  ConsumerState<ShortHashtagPage> createState() => _ShortHashtagPageState();
}

class _ShortHashtagPageState extends ConsumerState<ShortHashtagPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (_scroll.offset >= max - 280) {
      unawaited(ref.read(shortHashtagFeedProvider(widget.name).notifier).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(shortHashtagFeedProvider(widget.name));

    return Scaffold(
      backgroundColor: ShortsPremiumTheme.chromeBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('#${widget.name.replaceAll('#', '')}'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(shortHashtagFeedProvider(widget.name).notifier).refresh(),
        child: feed.when(
          loading: () => const PremiumShortGridSkeleton(count: 8),
          error: (e, _) => Center(child: Text('$e')),
          data: (state) {
            final list = state.videos;
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: Center(
                      child: Text(
                        'Bu hashtag ile video yok',
                        style: TextStyle(color: context.colors.onSurfaceMuted),
                      ),
                    ),
                  ),
                ],
              );
            }
            return CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text(
                      '${list.length}${state.hasMore ? '+' : ''} video',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 9 / 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i >= list.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final v = list[i];
                        return ListPerf.repaint(
                          HeroShortThumb(
                            videoId: v.id,
                            child: GestureDetector(
                              onTap: () =>
                                  context.push('/shorts?videoId=${v.id}'),
                              child: ClipRRect(
                                borderRadius: ShortsPremiumTheme.tileRadius,
                                child: v.thumbnailUrl != null
                                    ? CanlifalNetworkImage(
                                        url: v.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : ColoredBox(
                                        color: context.colors.surfaceElevated,
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          color: context.colors.onSurfaceMuted,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount:
                          list.length + (state.loadingMore ? 1 : 0),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
