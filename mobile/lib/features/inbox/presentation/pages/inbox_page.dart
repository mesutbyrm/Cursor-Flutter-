import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../messages/presentation/providers/conversations_list_notifier.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../messages/presentation/widgets/conversations_list_sliver.dart';
import '../../../notifications/presentation/providers/notifications_list_notifier.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../domain/inbox_tab.dart';
import '../widgets/inbox_all_feed_sliver.dart';
import '../widgets/inbox_system_notifications_panel.dart';

/// TikTok tarzı birleşik gelen kutusu — mesajlar + sistem bildirimleri.
class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({
    super.key,
    this.initialTab = InboxTab.all,
  });

  final InboxTab initialTab;

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  late InboxTab _tab;
  final _scroll = ScrollController();
  final _search = TextEditingController();
  var _query = '';
  var _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _scroll.addListener(_onScroll);
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      ref.read(conversationsListNotifierProvider.future),
      ref.read(notificationsListNotifierProvider.future),
    ]);
  }

  void _onScroll() {
    if (!_scroll.hasClients || _tab != InboxTab.messages) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) {
      ref.read(conversationsListNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void didUpdateWidget(covariant InboxPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab && _tab != widget.initialTab) {
      setState(() => _tab = widget.initialTab);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(conversationsListNotifierProvider.notifier).refresh(
            forceRefresh: true,
          ),
      ref.read(notificationsListNotifierProvider.notifier).refresh(),
    ]);
    ref.invalidate(conversationsProvider);
    ref.invalidate(notificationsListProvider);
    ref.invalidate(notificationsUnreadApiProvider);
  }

  void _selectTab(InboxTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    if (_tab == InboxTab.system) {
      return DiscoverSubPage(
        title: 'Gelen Kutusu',
        subtitle: 'Sistem bildirimleri',
        onRefresh: _refresh,
        actions: [
          DiscoverIconButton(
            icon: Icons.forum_outlined,
            tooltip: 'Mesajlar',
            onPressed: () => _selectTab(InboxTab.messages),
          ),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _InboxTabBar(
                selected: _tab,
                onSelect: _selectTab,
              ),
            ),
            const Expanded(
              child: InboxSystemNotificationsPanel(
                showPermissionBanner: true,
              ),
            ),
          ],
        ),
      );
    }

    return DiscoverTabScrollPage(
      title: 'Gelen Kutusu',
      subtitle: 'Mesajlar ve sistem bildirimleri',
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
      ],
      scrollController: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InboxTabBar(
                  selected: _tab,
                  onSelect: _selectTab,
                ),
                const SizedBox(height: 12),
                _InboxSearchPanel(
                  controller: _search,
                  query: _query,
                  unreadOnly: _unreadOnly,
                  onChanged: (v) => setState(() => _query = v),
                  onUnreadChanged: (v) => setState(() => _unreadOnly = v),
                ),
              ],
            ),
          ),
        ),
        if (_tab == InboxTab.all) ...[
          SliverToBoxAdapter(
            child: InboxSystemPinnedTile(
              onTap: () => _selectTab(InboxTab.system),
            ),
          ),
          InboxAllFeedSliver(query: _query, unreadOnly: _unreadOnly),
        ] else
          ConversationsListSliver(query: _query, unreadOnly: _unreadOnly),
      ],
    );
  }
}

class _InboxTabBar extends StatelessWidget {
  const _InboxTabBar({
    required this.selected,
    required this.onSelect,
  });

  final InboxTab selected;
  final ValueChanged<InboxTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < InboxTab.values.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i < InboxTab.values.length - 1 ? 8 : 0,
              ),
              child: _InboxTabChip(
                label: InboxTab.values[i].label,
                selected: selected == InboxTab.values[i],
                onTap: () => onSelect(InboxTab.values[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _InboxTabChip extends StatelessWidget {
  const _InboxTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFB832FF)],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppThemeColors.accentPurple.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _InboxSearchPanel extends StatelessWidget {
  const _InboxSearchPanel({
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
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
