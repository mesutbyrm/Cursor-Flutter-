import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live_psychics/presentation/controllers/psychic_incoming_controller.dart';
import '../../../live_psychics/presentation/controllers/psychic_invite_coordinator.dart';
import '../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../../live_psychics/presentation/providers/psychic_push_payload.dart';
import '../../../notifications/domain/entities/app_notification_entity.dart';
import '../../../notifications/domain/notification_action.dart';
import '../../../notifications/presentation/providers/notifications_list_notifier.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../notifications/presentation/widgets/notification_permission_banner.dart';
import '../../../voice_hub/presentation/utils/voice_room_session_utils.dart';
import '../utils/inbox_notification_visual.dart';

/// Sistem bildirimleri listesi — canlı yayın, sesli oda, kazanç vb.
class InboxSystemNotificationsPanel extends ConsumerStatefulWidget {
  const InboxSystemNotificationsPanel({
    super.key,
    this.scrollController,
    this.showPermissionBanner = true,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 32),
  });

  final ScrollController? scrollController;
  final bool showPermissionBanner;
  final EdgeInsets padding;

  @override
  ConsumerState<InboxSystemNotificationsPanel> createState() =>
      _InboxSystemNotificationsPanelState();
}

class _InboxSystemNotificationsPanelState
    extends ConsumerState<InboxSystemNotificationsPanel> {
  var _listReady = false;
  late final ScrollController _scroll;
  late final bool _ownsScroll;
  late final VoidCallback _detachPagination;

  @override
  void initState() {
    super.initState();
    _ownsScroll = widget.scrollController == null;
    _scroll = widget.scrollController ?? ScrollController();
    _detachPagination = ScrollPerf.bindPagination(
      _scroll,
      () => ref.read(notificationsListNotifierProvider.notifier).loadMore(),
    );
    Future<void>.delayed(LazyLoadPerf.notificationsList, () {
      if (mounted) setState(() => _listReady = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(notificationsUnreadApiProvider);
    });
  }

  @override
  void dispose() {
    _detachPagination();
    if (_ownsScroll) _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(notificationsListNotifierProvider.notifier).refresh();
    ref.invalidate(notificationsListProvider);
  }

  Future<void> _markAllRead() async {
    await markAllNotificationsRead(ref);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm sistem bildirimleri okundu')),
    );
  }

  Future<void> _onNotificationTap(
    AppNotificationEntity n,
    GoRouter router,
    bool staffCanManage,
  ) async {
    Future<void> prepareSwitch(String key, {String source = 'notification'}) =>
        prepareVoiceRoomSwitch(ref, nextLiveKey: key, source: source);

    final invite = psychicInviteFromNotification(n);
    if (invite != null) {
      final uid = ref.read(authControllerProvider).valueOrNull?.id;
      final approved = ref.read(approvedPsychicProvider);
      if (shouldPresentPsychicIncomingInvite(
        authUserId: uid,
        invite: invite,
        tellerProfileId: approved.profile?.id,
        isFortuneTeller:
            approved.profile != null && approved.profile!.isUsable,
      )) {
        ref.read(psychicIncomingQueueProvider.notifier).enqueue(invite);
        PsychicInviteCoordinator.requestPresent(sessionId: invite.sessionId);
      } else {
        await navigateFromNotificationAsync(
          router,
          n,
          staffCanManagePayments: staffCanManage,
          prepareVoiceRoomSwitch: prepareSwitch,
        );
      }
    } else {
      await navigateFromNotificationAsync(
        router,
        n,
        staffCanManagePayments: staffCanManage,
        prepareVoiceRoomSwitch: prepareSwitch,
      );
    }

    if (!n.read) {
      unawaited(markNotificationRead(ref, n.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    Widget listBody;
    if (!_listReady) {
      listBody = const DiscoverAccentLoader();
    } else {
      listBody = ref.watch(notificationsListNotifierProvider).when(
            loading: () => const DiscoverAccentLoader(),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.notifications_off_outlined,
              message: ApiException.userMessage(e),
              actionLabel: 'Yenile',
              action: _refresh,
            ),
            data: (state) {
              if (state.all.isEmpty) {
                return const DiscoverEmptyState(
                  icon: Icons.notifications_none_rounded,
                  message:
                      'Henüz sistem bildirimin yok.\nCanlı yayın, sesli oda, kazanç ve diğer uyarılar burada görünür.',
                );
              }
              return _InboxSystemListView(
                state: state,
                fmt: fmt,
                scrollController: _scroll,
                padding: widget.padding,
                onLoadMore: () => ref
                    .read(notificationsListNotifierProvider.notifier)
                    .loadMore(),
                onTap: (n) => _onNotificationTap(
                  n,
                  GoRouter.of(context),
                  ref.watch(staffAccessProvider).canManagePayments,
                ),
              );
            },
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showPermissionBanner) const NotificationPermissionBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Canlı yayın, sesli oda, Canlı Falcılar ve kazanç bildirimleri',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: _markAllRead,
                child: const Text('Tümünü oku'),
              ),
            ],
          ),
        ),
        Expanded(child: listBody),
      ],
    );
  }
}

class _InboxSystemListView extends StatelessWidget {
  const _InboxSystemListView({
    required this.state,
    required this.fmt,
    required this.scrollController,
    required this.padding,
    required this.onLoadMore,
    required this.onTap,
  });

  final NotificationsListState state;
  final DateFormat fmt;
  final ScrollController scrollController;
  final EdgeInsets padding;
  final VoidCallback onLoadMore;
  final ValueChanged<AppNotificationEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final items = state.visible;

    return ListView.separated(
      scrollCacheExtent: ScrollPerf.scrollCache(ListPerf.cacheExtent),
      controller: scrollController,
      padding: padding,
      itemCount: items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        if (i >= items.length) {
          onLoadMore();
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final n = items[i];
        return InboxSystemNotificationTile(
          notification: n,
          fmt: fmt,
          onTap: () => onTap(n),
        );
      },
    );
  }
}

class InboxSystemNotificationTile extends StatelessWidget {
  const InboxSystemNotificationTile({
    super.key,
    required this.notification,
    required this.fmt,
    required this.onTap,
  });

  final AppNotificationEntity notification;
  final DateFormat fmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final (icon, accent) = inboxNotificationVisual(n.type, context);
    final category = inboxSystemCategoryLabel(n.type);

    return ListPerf.repaint(
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: n.read
                  ? Colors.transparent
                  : accent.withValues(alpha: 0.07),
            ),
            child: ProGlassListTile(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _InboxSystemAvatar(
                    imageUrl: n.imageUrl,
                    icon: icon,
                    accent: accent,
                    read: n.read,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Canlifal',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.colors.onSurfaceMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.title,
                          style: TextStyle(
                            fontWeight:
                                n.read ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (n.body != null && n.body!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            n.body!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.colors.onSurfaceMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fmt.format((n.createdAt ?? DateTime.now()).toLocal()),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.onSurfaceMuted
                              .withValues(alpha: 0.85),
                        ),
                      ),
                      if (!n.read) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InboxSystemAvatar extends StatelessWidget {
  const _InboxSystemAvatar({
    required this.imageUrl,
    required this.icon,
    required this.accent,
    required this.read,
  });

  final String? imageUrl;
  final IconData icon;
  final Color accent;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: read ? 0.35 : 0.65),
                width: read ? 1 : 1.5,
              ),
            ),
            child: ClipOval(
              child: url != null && url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      memCacheWidth: 128,
                      memCacheHeight: 128,
                      errorWidget: (_, _, _) => _iconFallback(),
                      placeholder: (_, _) => _iconFallback(),
                    )
                  : _iconFallback(),
            ),
          ),
          if (!read)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconFallback() {
    return ColoredBox(
      color: accent.withValues(alpha: 0.15),
      child: Center(
        child: Icon(icon, color: accent, size: 22),
      ),
    );
  }
}
