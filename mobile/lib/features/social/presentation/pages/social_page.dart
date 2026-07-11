import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../widgets/instagram/social_instagram_app_bar.dart';
import '../widgets/instagram/social_feed_composer.dart';

import '../providers/social_providers.dart';
import '../widgets/social_feed_scroll_view.dart';

/// CanlıFal Sosyal — premium mistik akış.
class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends ConsumerState<SocialPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(socialNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(socialNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 88;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RepaintBoundary(child: SocialInstagramAppBar()),
            const RepaintBoundary(child: SocialFeedComposer()),
            Expanded(
              child: SocialFeedScrollView(
                controller: _scroll,
                onRefresh: _refresh,
                bottomPadding: bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
