import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../providers/conversations_list_notifier.dart';
import '../providers/messages_providers.dart';
import '../widgets/conversations_list_sliver.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  var _query = '';
  var _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Global poll: DmRealtimeListener (12s) — çift istek önlenir.
  }

  @override
  void dispose() {
    _search.dispose();
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
        DiscoverIconButton(
          icon: Icons.edit_square,
          tooltip: 'Yeni mesaj',
          onPressed: () => context.push('/search'),
        ),
        DiscoverIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Ara',
          onPressed: () => _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          ),
        ),
        DiscoverIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Bildirimler',
          onPressed: () => context.push('/notifications'),
        ),
      ],
      scrollController: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _MessagesSearchPanel(
              controller: _search,
              query: _query,
              unreadOnly: _unreadOnly,
              onChanged: (v) => setState(() => _query = v),
              onUnreadChanged: (v) => setState(() => _unreadOnly = v),
            ),
          ),
        ),
        ConversationsListSliver(query: _query, unreadOnly: _unreadOnly),
      ],
    );
  }
}

class _MessagesSearchPanel extends StatelessWidget {
  const _MessagesSearchPanel({
    required this.controller,
    required this.query,
    required this.unreadOnly,
    required this.onChanged,
    required this.onUnreadChanged,
  });

  final TextEditingController controller;
  final String query;
  final bool unreadOnly;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onUnreadChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppThemeColors.accentPurple.withValues(alpha: 0.20),
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Ara...',
              hintStyle: TextStyle(color: context.colors.onSurfaceMuted),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            _FilterChip(
              label: 'Tümü',
              selected: !unreadOnly,
              onTap: () => onUnreadChanged(false),
            ),
            _FilterChip(
              label: 'Okunmamış',
              selected: unreadOnly,
              onTap: () => onUnreadChanged(true),
            ),
            const _FilterChip(label: 'Favoriler'),
            const _FilterChip(label: 'Gruplar'),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFB832FF)])
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppThemeColors.accentPurple.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
