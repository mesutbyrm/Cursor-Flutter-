import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../messages/presentation/providers/conversations_list_notifier.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../messages/presentation/providers/messages_mark_read_providers.dart';
import '../../../messages/presentation/widgets/conversations_list_sliver.dart';
import '../../../notifications/presentation/providers/notifications_list_notifier.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../domain/inbox_tab.dart';
import '../providers/inbox_unread_providers.dart';
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

  Future<void> _markAllMessagesRead() async {
    await markAllMessagesRead(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm mesajlar okundu olarak işaretlendi')),
    );
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
        if (_tab == InboxTab.messages)
          DiscoverIconButton(
            icon: Icons.done_all_rounded,
            tooltip: 'Tümünü oku',
            onPressed: () => unawaited(_markAllMessagesRead()),
          ),
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
            child: _InboxSectionCards(
              onMessages: () => _selectTab(InboxTab.messages),
              onSystem: () => _selectTab(InboxTab.system),
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

/// Gelen kutusu üst kartları — Mesajlar (okunmamış sayısı) ve Sistem Bildirimleri
/// (okunmamış sayısı). Kartlardan birine dokununca ilgili bölüm açılır.
class _InboxSectionCards extends ConsumerWidget {
  const _InboxSectionCards({
    required this.onMessages,
    required this.onSystem,
  });

  final VoidCallback onMessages;
  final VoidCallback onSystem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(inboxMessagesUnreadCountProvider);
    final system = ref.watch(inboxSystemUnreadCountProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _InboxSectionCard(
              icon: Icons.forum_rounded,
              title: 'Mesajlar',
              count: messages,
              color: AppThemeColors.accentCyan,
              onTap: onMessages,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InboxSectionCard(
              icon: Icons.notifications_rounded,
              title: 'Sistem Bildirimleri',
              count: system,
              color: AppThemeColors.accentPurple,
              onTap: onSystem,
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxSectionCard extends StatelessWidget {
  const _InboxSectionCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const Spacer(),
                // Okunmamış sayısı — bölümün üstünde.
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: count > 0
                        ? color
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              count > 0 ? '$count okunmamış' : 'Tümü okundu',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
