import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../domain/notification_action.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live_psychics/presentation/controllers/psychic_incoming_controller.dart';
import '../../../live_psychics/presentation/controllers/psychic_invite_coordinator.dart';
import '../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../../live_psychics/presentation/providers/psychic_push_payload.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../providers/notifications_list_notifier.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../providers/notifications_providers.dart';
import '../widgets/notification_permission_banner.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scroll = ScrollController();
  var _listReady = false;
  late final VoidCallback _detachPagination;

  @override
  void initState() {
    super.initState();
    _detachPagination = ScrollPerf.bindPagination(
      _scroll,
      () => ref.read(notificationsListNotifierProvider.notifier).loadMore(),
    );
    Future<void>.delayed(LazyLoadPerf.notificationsList, () {
      if (mounted) setState(() => _listReady = true);
    });
    // Sayfaya girince otomatik hepsini okundu YAPMA — kullanıcı hangisine
    // tıklarsa o okundu olur (Instagram davranışı). Toplu okuma için "Tümünü oku".
  }

  @override
  void dispose() {
    _detachPagination();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(notificationsListNotifierProvider.notifier).refresh();
    ref.invalidate(notificationsListProvider);
  }

  Future<void> _markAllRead({bool silent = false}) async {
    await markAllNotificationsRead(ref);
    if (!silent) {
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm bildirimler okundu')),
      );
    }
  }

  void _onNotificationTap(
    AppNotificationEntity n,
    GoRouter router,
    bool staffCanManage,
  ) {
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
        navigateFromNotification(
          router,
          n,
          staffCanManagePayments: staffCanManage,
        );
      }
    } else {
      navigateFromNotification(
        router,
        n,
        staffCanManagePayments: staffCanManage,
      );
    }

    if (!n.read) {
      ref.read(notificationsListNotifierProvider.notifier).markOneReadLocally(n.id);
      unawaited(
        ref.read(notificationsRepositoryProvider).markRead(n.id).catchError((_) {}),
      );
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
                  message: 'Henüz bildirimin yok.',
                );
              }
              return _NotificationsListView(
                state: state,
                fmt: fmt,
                scrollController: _scroll,
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

    return DiscoverSubPage(
      title: 'Bildirimler',
      subtitle: 'Son aktiviteler ve uyarılar',
      onRefresh: _refresh,
      actions: [
        TextButton(
          onPressed: () => _markAllRead(),
          child: const Text('Tümünü oku'),
        ),
        DiscoverIconButton(
          icon: Icons.refresh_rounded,
          onPressed: _refresh,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NotificationPermissionBanner(),
          Expanded(child: listBody),
        ],
      ),
    );
  }
}

/// Bildirim tipine göre Instagram tarzı renkli ikon.
(IconData, Color) _notificationVisual(String? type, BuildContext context) {
  final t = (type ?? '').toLowerCase();
  if (t.contains('like') || t.contains('begeni') || t.contains('beğeni')) {
    return (Icons.favorite_rounded, const Color(0xFFFF3B6B));
  }
  if (t.contains('comment') || t.contains('yorum')) {
    return (Icons.chat_bubble_rounded, const Color(0xFF4F9DFF));
  }
  if (t.contains('follow') || t.contains('takip')) {
    return (Icons.person_add_rounded, const Color(0xFF7B5CFF));
  }
  if (t.contains('gift') || t.contains('hediye')) {
    return (Icons.card_giftcard_rounded, const Color(0xFFFFB020));
  }
  if (t.contains('payment') ||
      t.contains('odeme') ||
      t.contains('ödeme') ||
      t.contains('cfc') ||
      t.contains('jeton')) {
    return (Icons.account_balance_wallet_rounded, const Color(0xFF22C55E));
  }
  if (t.contains('live') ||
      t.contains('yayin') ||
      t.contains('yayın') ||
      t.contains('voice') ||
      t.contains('oda')) {
    return (Icons.podcasts_rounded, const Color(0xFFFF4D4D));
  }
  if (t.contains('fortune') ||
      t.contains('fal') ||
      t.contains('psychic') ||
      t.contains('seans')) {
    return (Icons.auto_awesome_rounded, const Color(0xFFFFD54F));
  }
  if (t.contains('message') || t.contains('mesaj')) {
    return (Icons.mail_rounded, const Color(0xFF4F9DFF));
  }
  return (Icons.notifications_rounded, const Color(0xFF7B5CFF));
}

class _NotificationsListView extends StatelessWidget {
  const _NotificationsListView({
    required this.state,
    required this.fmt,
    required this.scrollController,
    required this.onLoadMore,
    required this.onTap,
  });

  final NotificationsListState state;
  final DateFormat fmt;
  final ScrollController scrollController;
  final VoidCallback onLoadMore;
  final ValueChanged<AppNotificationEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final items = state.visible;

    return ListView.separated(
      cacheExtent: ListPerf.cacheExtent,
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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
        final (icon, accent) = _notificationVisual(n.type, context);
        return ListPerf.repaint(
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onTap(n),
              child: ProGlassListTile(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: n.read
                            ? null
                            : LinearGradient(
                                colors: [
                                  accent,
                                  accent.withValues(alpha: 0.65),
                                ],
                              ),
                        color: n.read
                            ? Colors.white.withValues(alpha: 0.06)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: n.read
                            ? context.colors.onSurfaceMuted
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
        );
      },
    );
  }
}
