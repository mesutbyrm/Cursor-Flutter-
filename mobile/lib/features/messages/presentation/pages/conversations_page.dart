import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../providers/conversations_list_notifier.dart';
import '../providers/messages_providers.dart';
import '../widgets/conversations_list_sliver.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  Timer? _poll;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      ref.read(conversationsListNotifierProvider.notifier).refresh(
            silent: true,
            forceRefresh: true,
          );
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - ListPerf.preloadThresholdPx) {
      ref.read(conversationsListNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(conversationsListNotifierProvider.notifier).refresh(
          forceRefresh: true,
        );
    ref.invalidate(conversationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverTabScrollPage(
      title: 'Mesajlar',
      subtitle: 'Sohbetlerin ve grup mesajların',
      onRefresh: _refresh,
      actions: [
        const MessagesNotificationsActions(spacing: 4),
        DiscoverIconButton(
          icon: Icons.refresh_rounded,
          onPressed: _refresh,
        ),
      ],
      scrollController: _scroll,
      slivers: const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: MessagesBranchQuickActions(),
          ),
        ),
        ConversationsListSliver(),
      ],
    );
  }
}
