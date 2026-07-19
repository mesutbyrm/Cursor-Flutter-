import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/otp_verify_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../features/content_hub/domain/native_feature_item.dart';
import '../../features/content_hub/presentation/pages/content_hub_page.dart';
import '../../features/content_hub/presentation/pages/native_feature_hub_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/search/presentation/pages/global_search_page.dart';
import '../../features/fortune/domain/entities/fortune_type_entity.dart';
import '../../features/fortune/presentation/data/fortune_catalog.dart';
import '../../features/fortune/presentation/pages/daily_fortune_open_page.dart';
import '../../features/fortune/presentation/pages/daily_fortune_result_page.dart';
import '../../features/fortune/presentation/pages/fortune_detail_page.dart';
import '../../features/fortune/presentation/pages/fortune_type_intro_page.dart';
import '../../features/fortune/presentation/pages/fortune_result_page.dart';
import '../../features/fortune/presentation/pages/fortune_session_page.dart';
import '../../features/fortune/presentation/pages/fortune_ready_readings_page.dart';

import '../../features/admin/presentation/pages/admin_panel_page.dart';
import '../../features/admin/presentation/pages/admin_voice_room_backgrounds_page.dart';
import '../../features/admin/presentation/pages/admin_hub_page.dart';
import '../../features/admin/presentation/pages/admin_sub_pages.dart';
import '../../features/fortune/presentation/pages/fortune_tarot_hub_page.dart';
import '../../features/fortune/presentation/pages/fortune_types_all_page.dart';
import '../../features/gifts/presentation/pages/gift_send_page.dart';
import '../../features/live/domain/entities/live_broadcast_session.dart';
import '../../features/live/domain/entities/live_broadcast_prep_args.dart';
import '../../features/live/presentation/pages/live_broadcast_prep_page.dart';
import '../../features/live/presentation/pages/live_broadcast_schedule_page.dart';
import '../../features/live/presentation/pages/live_broadcast_type_page.dart';
import '../../features/gifts/presentation/pages/gift_leaderboard_hub_page.dart';
import '../../features/live/domain/entities/live_swipe_feed_args.dart';
import '../../features/live/presentation/pages/live_broadcast_room_page.dart';
import '../../features/live/presentation/pages/live_page.dart';
import '../../features/live/presentation/pages/live_swipe_viewer_page.dart';
import '../../features/social/presentation/pages/social_create_post_page.dart';
import '../../features/social/presentation/pages/social_page.dart';
import '../../features/gifts/presentation/pages/gift_collection_page.dart';
import '../../features/gifts/domain/admin_gift_type.dart';
import '../../features/gifts/presentation/pages/admin_gift_management_page.dart';
import '../../features/gifts/presentation/pages/admin_gift_editor_page.dart';
import '../../features/gifts/presentation/pages/gift_history_page.dart';
import '../../features/live/presentation/pages/pk_leaderboard_page.dart';
import '../../features/live/presentation/pages/pk_moderation_page.dart';
import '../../features/live/presentation/pages/pk_room_history_page.dart';
import '../../features/gifts/presentation/pages/gift_hub_page.dart';
import '../../features/gifts/presentation/pages/gift_leaderboard_center_page.dart';
import '../../features/shorts/presentation/pages/shorts_feed_page.dart';
import '../../features/shorts/presentation/pages/shorts_explore_page.dart';
import '../../features/shorts/presentation/pages/short_hashtag_page.dart';
import '../../features/shorts/presentation/studio/shorts_studio_page.dart';
import '../../features/shorts/presentation/utils/short_studio_launch.dart';
import '../../features/messages/presentation/pages/chat_page.dart';
import '../../features/messages/presentation/pages/conversations_page.dart';
import '../../features/messages/presentation/pages/dm_voice_call_page.dart';
import '../../features/moderation/domain/entities/report_target.dart';
import '../../features/moderation/presentation/pages/report_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/invite_friends_page.dart';
import '../../features/membership/presentation/pages/premium_membership_page.dart';
import '../../features/profile/presentation/pages/cfc_purchase_page.dart';
import '../../features/profile/presentation/pages/jeton_purchase_page.dart';
import '../../features/wallet/presentation/pages/wallet_center_page.dart';
import '../../features/profile/presentation/pages/profile_about_page.dart';
import '../../features/legal/domain/legal_document.dart';
import '../../features/legal/presentation/pages/site_content_page.dart';
import '../../features/profile/presentation/pages/profile_account_security_page.dart';
import '../../features/profile/presentation/pages/profile_broadcast_history_page.dart';
import '../../features/profile/presentation/pages/profile_broadcaster_stats_page.dart';
import '../../features/profile/presentation/pages/profile_earnings_page.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/profile/presentation/profile_hub/profile_qr_page.dart';
import '../../features/profile/presentation/pages/profile_equipment_page.dart';
import '../../features/profile/presentation/pages/profile_follow_list_page.dart';
import '../../features/profile/presentation/pages/profile_gifts_page.dart';
import '../../features/profile/presentation/pages/growth_hub_page.dart';
import '../../features/cosmetics/presentation/pages/profile_cosmetics_page.dart';
import '../../features/profile/presentation/pages/profile_help_support_page.dart';
import '../../features/profile/presentation/pages/profile_payment_notice_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/profile_visitors_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/debug/presentation/api_monitor_page.dart';
import '../../features/profile/presentation/pages/active_devices_page.dart';
import '../../features/profile/presentation/pages/profile_transactions_page.dart';
import '../../features/profile/presentation/pages/user_profile_page.dart';
import '../../features/shell/presentation/main_shell_page.dart';
import '../../features/live/domain/entities/live_stream_entity.dart';
import '../../features/live/domain/entities/voice_room_entity.dart';
import '../../features/live/presentation/pages/live_pk_battle_page.dart';
import '../../features/live/presentation/pages/live_pk_invite_page.dart';
import '../../features/voice_hub/presentation/pages/pk_history_page.dart';
import '../../features/voice_hub/presentation/pages/pk_invite_page.dart';
import '../../features/voice_hub/presentation/pages/pk_result_page.dart';
import '../../features/voice_hub/presentation/pages/voice_pk_battle_page.dart';
import '../../features/voice_hub/presentation/voice_room_route_page.dart';
import '../../features/voice_hub/presentation/basic/voice_room_page.dart';
import '../../features/voice_hub/presentation/widgets/voice_room_error_boundary.dart';
import '../../features/voice_hub/presentation/voice_rooms_hub_page.dart';
import '../../features/live_psychics/domain/entities/psychic_session_entity.dart';
import '../../features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../features/live_psychics/presentation/screens/psychic_session_route.dart';
import '../../features/live_psychics/presentation/screens/psychic_apply_screen.dart';
import '../../features/live_psychics/presentation/screens/psychic_become_teller_page.dart';
import '../../features/live_psychics/presentation/screens/psychic_teller_dashboard_screen.dart';
import '../../features/live_psychics/presentation/screens/psychic_profile_screen.dart';
import '../../features/live_psychics/presentation/screens/psychics_list_screen.dart';
import '../../features/agency/presentation/pages/agency_dashboard_screen.dart';
import '../../features/agency/presentation/providers/agency_providers.dart';
import '../../features/vip_gold/presentation/pages/vip_gold_hub_page.dart';
import '../../core/bootstrap/app_startup_log.dart';
import '../../core/bootstrap/auth_redirect.dart';
import '../../core/bootstrap/startup_route_observer.dart';
import '../../core/navigation/app_page_transitions.dart';
import '../../core/network/loading_timeout.dart';

/// Push / global modal sheet'ler için kök navigator (oturum değişince yenilenir).
GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root-nav-0');

void resetRootNavigatorKey(int session) {
  rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root-nav-$session');
}

/// Giriş, çıkış veya misafir geçişinde go_router sıfırdan.
final shellSessionProvider = StateProvider<int>((ref) => 0);

final goRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(shellSessionProvider);
  // Ajans onayı değişince tüm router'ı yeniden oluşturma — redirect içinde okunur.

  Future<ApprovedPsychicState> readApprovedTellerState() async {
    var approved = ref.read(approvedPsychicProvider);
    if (approved.checked) return approved;
    try {
      await LoadingTimeout.run(
        ref.read(approvedPsychicProvider.notifier).refresh(),
        timeout: const Duration(seconds: 10),
      );
    } catch (_) {}
    return ref.read(approvedPsychicProvider);
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/feed',
    observers: [StartupRouteObserver()],
    redirect: (context, state) {
      final path = state.uri.path;
      final loc = state.matchedLocation;
      final auth = ref.read(authControllerProvider);

      if (auth.isLoading) return null;

      if (path == '/splash') {
        final target = AuthRedirect.targetFor(
          path: path,
          matchedLocation: loc,
          user: auth.valueOrNull,
          guest: ref.read(guestModeProvider),
        );
        if (target != null) {
          AppStartupLog.route('/splash', target, reason: 'legacy splash → auth');
        }
        return target;
      }

      if (loc == '/login' || loc == '/register') {
        AppStartupLog.auth(
          loading: auth.isLoading,
          hasUser: auth.valueOrNull != null,
          hasError: auth.hasError,
        );
      }

      final target = AuthRedirect.targetFor(
        path: path,
        matchedLocation: loc,
        user: auth.valueOrNull,
        guest: ref.read(guestModeProvider),
      );
      if (target == null || target == loc || target == path) return null;
      AppStartupLog.route(loc, target, reason: 'auth redirect');
      return target;
    },
    routes: [
      GoRoute(
        path: '/login',
        redirect: (context, state) => '/feed',
      ),
      GoRoute(
        path: '/register',
        redirect: (context, state) => '/feed',
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (context, state) => AppPageTransitions.none(
          key: state.pageKey,
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: '/auth/reset-password',
        pageBuilder: (context, state) => AppPageTransitions.none(
          key: state.pageKey,
          child: ResetPasswordPage(
            token: state.uri.queryParameters['token'],
          ),
        ),
      ),
      GoRoute(
        path: '/falci-panel',
        redirect: (context, state) async {
          final approved = await readApprovedTellerState();
          if (approved.isApprovedTeller) {
            return '/canli-falcilar/dashboard';
          }
          return '/falci-ol';
        },
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PsychicTellerDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/falci-ol',
        redirect: (context, state) async {
          final approved = await readApprovedTellerState();
          if (approved.isApprovedTeller) {
            return '/canli-falcilar/dashboard';
          }
          return null;
        },
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PsychicBecomeTellerPage(),
        ),
      ),
      GoRoute(
        path: '/ajans-ol',
        redirect: (context, state) async {
          var approved = ref.read(approvedAgencyProvider);
          if (!approved.checked) {
            await ref.read(approvedAgencyProvider.notifier).refresh();
            approved = ref.read(approvedAgencyProvider);
          }
          if (approved.isApprovedAgency) {
            return '/ajans/dashboard';
          }
          return '/content-hub';
        },
      ),
      GoRoute(
        path: '/auth/otp-verify',
        pageBuilder: (context, state) => AppPageTransitions.none(
          key: state.pageKey,
          child: OtpVerifyPage(email: state.extra as String?),
        ),
      ),
      // indexedStack tüm sekmeleri önceden yükler; Android BackdropFilter gri ekran yapar.
      StatefulShellRoute(
        navigatorContainerBuilder: (context, navigationShell, children) {
          return children[navigationShell.currentIndex];
        },
        pageBuilder: (context, state, navigationShell) {
          return AppPageTransitions.none(
            key: state.pageKey,
            child: MainShellPage(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                pageBuilder: (context, state) => AppPageTransitions.none(
                  key: state.pageKey,
                  child: const FeedPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                pageBuilder: (context, state) => AppPageTransitions.none(
                  key: state.pageKey,
                  child: const SocialPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'create',
                    pageBuilder: (context, state) =>
                        AppPageTransitions.fadeSlide(
                          key: state.pageKey,
                          child: SocialCreatePostPage(
                            initialCaption: state.extra as String?,
                          ),
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/live',
                pageBuilder: (context, state) => AppPageTransitions.none(
                  key: state.pageKey,
                  child: const LivePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/fortune',
                pageBuilder: (context, state) => AppPageTransitions.none(
                  key: state.pageKey,
                  child: const FortuneTarotHubPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'types',
                    pageBuilder: (context, state) =>
                        AppPageTransitions.fadeSlide(
                          key: state.pageKey,
                          child: const FortuneTypesAllPage(),
                        ),
                  ),
                  GoRoute(
                    path: 'ready',
                    pageBuilder: (context, state) =>
                        AppPageTransitions.fadeSlide(
                          key: state.pageKey,
                          child: const FortuneReadyReadingsPage(),
                        ),
                  ),
                  GoRoute(
                    path: 'history/:id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return AppPageTransitions.fadeSlide(
                        key: state.pageKey,
                        child: FortuneDetailPage(fortuneId: id),
                      );
                    },
                  ),
                  GoRoute(
                    path: ':slug',
                    pageBuilder: (context, state) {
                      final slug = state.pathParameters['slug']!;
                      final type = FortuneCatalog.bySlug(slug);
                      final child = type == null
                          ? const FortuneTarotHubPage()
                          : type.isDaily
                          ? DailyFortuneOpenPage(type: type)
                          : FortuneTypeIntroPage(type: type);
                      return AppPageTransitions.fadeSlide(
                        key: state.pageKey,
                        child: child,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'session',
                        pageBuilder: (context, state) {
                          final slug = state.pathParameters['slug']!;
                          final type = FortuneCatalog.bySlug(slug);
                          final child = type == null
                              ? const FortuneTarotHubPage()
                              : FortuneSessionPage(type: type);
                          return AppPageTransitions.fadeSlide(
                            key: state.pageKey,
                            child: child,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'result',
                        pageBuilder: (context, state) {
                          final result = state.extra as FortuneReadingResult?;
                          final child = result == null
                              ? const FortuneTarotHubPage()
                              : result.type.isDaily
                              ? DailyFortuneResultPage(result: result)
                              : FortuneResultPage(result: result);
                          return AppPageTransitions.fadeSlide(
                            key: state.pageKey,
                            child: child,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => AppPageTransitions.none(
                  key: state.pageKey,
                  child: const ProfilePage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/live/schedule',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const LiveBroadcastSchedulePage(),
        ),
      ),
      GoRoute(
        path: '/live/type',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const LiveBroadcastTypePage(),
        ),
      ),
      GoRoute(
        path: '/live/prep',
        pageBuilder: (context, state) {
          final args = state.extra as LiveBroadcastPrepArgs?;
          return AppPageTransitions.fadeSlide(
            key: state.pageKey,
            child: LiveBroadcastPrepPage(
              args: args ?? const LiveBroadcastPrepArgs(category: 'Sohbet'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/live/room',
        pageBuilder: (context, state) {
          final session = state.extra as LiveBroadcastSession?;
          final child = session == null
              ? const LiveBroadcastTypePage()
              : LiveBroadcastRoomPage(session: session);
          return AppPageTransitions.fadeSlide(key: state.pageKey, child: child);
        },
      ),
      GoRoute(
        path: '/live/swipe',
        pageBuilder: (context, state) {
          final args = state.extra as LiveSwipeFeedArgs?;
          final child = args == null || args.streams.isEmpty
              ? const LivePage()
              : LiveSwipeViewerPage(args: args);
          return AppPageTransitions.fadeSlide(key: state.pageKey, child: child);
        },
      ),
      GoRoute(
        path: '/messages',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const ConversationsPage(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/jeton-store',
        builder: (context, state) => const JetonPurchasePage(),
      ),
      GoRoute(
        path: '/cfc-store',
        builder: (context, state) => const CfcPurchasePage(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletCenterPage(),
      ),
      GoRoute(
        path: '/premium-membership',
        builder: (context, state) => const PremiumMembershipPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHubPage(),
      ),
      GoRoute(
        path: '/admin/panel',
        builder: (context, state) => const AdminPanelPage(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const AdminReportsPage(),
      ),
      GoRoute(
        path: '/admin/moderation',
        builder: (context, state) => const AdminModerationPage(),
      ),
      GoRoute(
        path: '/gift-send',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return GiftSendPage(
            streamId: q['streamId'],
            roomId: q['roomId'],
            receiverName: q['receiver'] ?? 'Yayıncı',
          );
        },
      ),
      GoRoute(
        path: '/invite-friends',
        builder: (context, state) => const InviteFriendsPage(),
      ),
      GoRoute(
        path: '/profile/qr',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const ProfileQrPage(),
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => AppPageTransitions.cupertinoSheet(
          key: state.pageKey,
          child: const ProfileEditPage(),
        ),
      ),
      GoRoute(
        path: '/profile/earnings',
        builder: (context, state) => const ProfileEarningsPage(),
      ),
      GoRoute(
        path: '/profile/transactions',
        builder: (context, state) => const ProfileTransactionsPage(),
      ),
      GoRoute(
        path: '/profile/payment-notice',
        builder: (context, state) => const ProfilePaymentNoticePage(),
      ),
      GoRoute(
        path: '/profile/broadcast-history',
        builder: (context, state) => const ProfileBroadcastHistoryPage(),
      ),
      GoRoute(
        path: '/profile/broadcaster-stats',
        builder: (context, state) => const ProfileBroadcasterStatsPage(),
      ),
      GoRoute(
        path: '/profile/equipment',
        builder: (context, state) => const ProfileEquipmentPage(),
      ),
      GoRoute(
        path: '/profile/gifts',
        builder: (context, state) => const ProfileGiftsPage(),
      ),
      GoRoute(
        path: '/gifts/leaderboard',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const GiftLeaderboardHubPage(),
        ),
      ),
      GoRoute(
        path: '/profile/growth',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const GrowthHubPage(),
        ),
      ),
      GoRoute(
        path: '/profile/cosmetics',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const ProfileCosmeticsPage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/settings/devices',
        builder: (context, state) => const ActiveDevicesPage(),
      ),
      if (kDebugMode)
        GoRoute(
          path: '/debug/api-monitor',
          builder: (context, state) => const ApiMonitorPage(),
        ),
      GoRoute(
        path: '/profile/security',
        builder: (context, state) => const ProfileAccountSecurityPage(),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (context, state) => const ProfileHelpSupportPage(),
      ),
      GoRoute(
        path: '/profile/about',
        builder: (context, state) => const ProfileAboutPage(),
      ),
      GoRoute(
        path: '/legal/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          final title = state.extra as String? ??
              kLegalDocuments
                  .where((d) => d.slug == slug)
                  .map((d) => d.title)
                  .firstOrNull ??
              'Yasal';
          final doc = kLegalDocuments
              .where((d) => d.slug == slug)
              .firstOrNull;
          return SiteContentPage(
            slug: slug,
            title: title,
            fallbackUrl: doc?.fallbackUrl,
          );
        },
      ),
      GoRoute(
        path: '/profile/followers',
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'] ?? '';
          return ProfileFollowListPage(
            userId: userId,
            tab: ProfileFollowTab.followers,
          );
        },
      ),
      GoRoute(
        path: '/profile/following',
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'] ?? '';
          return ProfileFollowListPage(
            userId: userId,
            tab: ProfileFollowTab.following,
          );
        },
      ),
      GoRoute(
        path: '/profile/visitors',
        builder: (context, state) => const ProfileVisitorsPage(),
      ),
      GoRoute(
        path: '/user/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final focusPostId = state.extra as String?;
          return AppPageTransitions.sharedAxis(
            key: state.pageKey,
            child: UserProfilePage(userId: id, focusPostId: focusPostId),
          );
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatPage(conversationId: id);
        },
      ),
      GoRoute(
        path: '/dm-voice-call',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            return DmVoiceCallPage(
              peerName: extra['peerName']?.toString() ?? 'Arama',
              channelId: extra['channelId']?.toString() ?? '',
            );
          }
          return const DmVoiceCallPage(peerName: 'Arama', channelId: '');
        },
      ),
      GoRoute(
        path: '/report',
        pageBuilder: (context, state) {
          final target = state.extra as ReportTarget?;
          final child = target == null
              ? const ReportPage(
                  target: ReportTarget(
                    type: ReportTargetType.user,
                    targetId: '',
                    displayTitle: 'Bilinmeyen',
                  ),
                )
              : ReportPage(target: target);
          return AppPageTransitions.fadeSlide(key: state.pageKey, child: child);
        },
      ),
      GoRoute(
        path: '/canlifal-web',
        builder: (context, state) => CanlifalWebRoute.fromState(state),
      ),
      GoRoute(
        path: '/content-hub',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const ContentHubPage(),
        ),
      ),
      GoRoute(
        path: '/gifts/leaderboard',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const GiftLeaderboardCenterPage(),
        ),
      ),
      GoRoute(
        path: '/admin/gifts',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const AdminGiftManagementPage(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const AdminGiftEditorPage(),
            ),
          ),
          GoRoute(
            path: ':giftId/edit',
            pageBuilder: (context, state) {
              final gift = state.extra;
              return AppPageTransitions.fadeSlide(
                key: state.pageKey,
                child: AdminGiftEditorPage(
                  gift: gift is AdminGiftType ? gift : null,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/voice-backgrounds',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const AdminVoiceRoomBackgroundsPage(),
        ),
      ),
      GoRoute(
        path: '/pk/leaderboard',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PkLeaderboardPage(),
        ),
      ),
      GoRoute(
        path: '/pk/moderation',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PkModerationPage(),
        ),
      ),
      GoRoute(
        path: '/pk/room-history',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PkRoomHistoryPage(),
        ),
      ),
      GoRoute(
        path: '/gifts/history',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const GiftHistoryPage(),
        ),
      ),
      GoRoute(
        path: '/gifts/hub',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const GiftHubPage(),
        ),
      ),
      GoRoute(
        path: '/gifts/collection',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: GiftCollectionPage(
            userId: state.uri.queryParameters['userId'],
          ),
        ),
      ),
      GoRoute(
        path: '/shorts',
        pageBuilder: (context, state) => AppPageTransitions.none(
          key: state.pageKey,
          child: ShortsFeedPage(
            initialVideoId: state.uri.queryParameters['videoId'],
          ),
        ),
        routes: [
          GoRoute(
            path: 'explore',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const ShortsExplorePage(),
            ),
          ),
          GoRoute(
            path: 'upload',
            pageBuilder: (context, state) => AppPageTransitions.cupertinoSheet(
              key: state.pageKey,
              child: ShortsStudioPage(
                launchParams: ShortStudioLaunchParams.fromUri(state.uri),
              ),
            ),
          ),
          GoRoute(
            path: 'hashtag/:name',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: ShortHashtagPage(
                name: state.pathParameters['name'] ?? '',
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/celebrities-hub',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const NativeFeatureHubPage(
            kind: NativeFeatureHubKind.celebrities,
          ),
        ),
      ),
      GoRoute(
        path: '/fan-club-hub',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const NativeFeatureHubPage(kind: NativeFeatureHubKind.fanClub),
        ),
      ),
      GoRoute(
        path: '/ad-rewards',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const NativeFeatureHubPage(
            kind: NativeFeatureHubKind.adRewards,
          ),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const GlobalSearchPage(),
        ),
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const FavoritesPage(),
        ),
      ),
      GoRoute(
        path: '/vip-gold',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const VipGoldHubPage(),
        ),
      ),
      GoRoute(
        path: '/ajans/dashboard',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const AgencyDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/canli-falcilar',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PsychicsListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'apply',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const PsychicApplyScreen(),
            ),
          ),
          GoRoute(
            path: 'dashboard',
            redirect: (context, state) async {
              final approved = await readApprovedTellerState();
              if (!approved.isApprovedTeller) {
                return '/falci-ol';
              }
              return null;
            },
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const PsychicTellerDashboardScreen(),
            ),
          ),
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return AppPageTransitions.fadeSlide(
                key: state.pageKey,
                child: PsychicProfileScreen(psychicId: id),
              );
            },
            routes: [
              GoRoute(
                path: 'waiting',
                pageBuilder: (context, state) {
                  final session = state.extra as PsychicSessionEntity?;
                  final id = state.pathParameters['id'] ?? '';
                  return AppPageTransitions.fadeSlide(
                    key: state.pageKey,
                    child: PsychicWaitingRoute(
                      psychicId: id,
                      session: session,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'ad-transition',
                pageBuilder: (context, state) {
                  final session = state.extra as PsychicSessionEntity?;
                  final id = state.pathParameters['id'] ?? '';
                  return AppPageTransitions.fadeSlide(
                    key: state.pageKey,
                    child: PsychicAdTransitionRoute(
                      psychicId: id,
                      session: session,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'session',
                pageBuilder: (context, state) {
                  final session = state.extra as PsychicSessionEntity?;
                  final id = state.pathParameters['id'] ?? '';
                  return AppPageTransitions.fadeSlide(
                    key: state.pageKey,
                    child: PsychicSessionRoute(
                      psychicId: id,
                      session: session,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/voice-rooms',
        pageBuilder: (context, state) => AppPageTransitions.none(
          key: state.pageKey,
          child: const VoiceRoomsHubPage(),
        ),
      ),
      GoRoute(
        path: '/voice-room/:id',
        pageBuilder: (context, state) {
          final room = state.extra as VoiceRoomEntity?;
          final Widget child;
          if (room != null) {
            final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
            child = VoiceRoomErrorBoundary(
              roomId: key,
              child: buildVoiceRoomPage(room),
            );
          } else {
            final id = state.pathParameters['id'] ?? '';
            child = VoiceRoomRoutePage(roomId: id);
          }
          return AppPageTransitions.none(key: state.pageKey, child: child);
        },
        routes: [
          GoRoute(
            path: 'pk',
            builder: (context, state) {
              final room = state.extra as VoiceRoomEntity?;
              if (room != null) {
                return VoicePkBattlePage(room: room);
              }
              final id = state.pathParameters['id'] ?? '';
              return VoiceRoomRoutePage(roomId: id);
            },
          ),
          GoRoute(
            path: 'pk-invite',
            builder: (context, state) {
              final room = state.extra as VoiceRoomEntity?;
              if (room == null) {
                return VoiceRoomRoutePage(
                  roomId: state.pathParameters['id'] ?? '',
                );
              }
              return PkInvitePage(room: room);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/live/pk-invite',
        builder: (context, state) {
          final session = state.extra as LiveBroadcastSession?;
          if (session == null) return const LiveBroadcastPrepPage();
          return LivePkInvitePage(session: session);
        },
      ),
      GoRoute(
        path: '/live/pk',
        builder: (context, state) {
          final extra = state.extra;
          LiveBroadcastSession? session;
          LiveStreamEntity? opponent;
          if (extra is LiveBroadcastSession) {
            session = extra;
          } else if (extra is Map) {
            session = extra['session'] as LiveBroadcastSession?;
            opponent = extra['opponent'] as LiveStreamEntity?;
          }
          if (session == null) return const LiveBroadcastPrepPage();
          return LivePkBattlePage(session: session, opponentStream: opponent);
        },
      ),
      GoRoute(
        path: '/pk/history',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return PkHistoryPage(battleType: type);
        },
      ),
      GoRoute(
        path: '/pk/result',
        builder: (context, state) => const PkResultPage(),
      ),
    ],
  );
});
