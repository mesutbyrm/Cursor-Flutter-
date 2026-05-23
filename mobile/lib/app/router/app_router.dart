import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verify_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/fortune/domain/entities/fortune_type_entity.dart';
import '../../features/fortune/presentation/data/fortune_catalog.dart';
import '../../features/fortune/presentation/pages/fortune_result_page.dart';
import '../../features/fortune/presentation/pages/fortune_session_page.dart';
import '../../features/admin/presentation/pages/admin_hub_page.dart';
import '../../features/fortune/presentation/pages/fortune_tarot_hub_page.dart';
import '../../features/gifts/presentation/pages/gift_send_page.dart';
import '../../features/live/domain/entities/live_broadcast_session.dart';
import '../../features/live/presentation/pages/live_broadcast_prep_page.dart';
import '../../features/live/presentation/pages/live_broadcast_room_page.dart';
import '../../features/live/presentation/pages/live_page.dart';
import '../../features/social/presentation/pages/social_create_post_page.dart';
import '../../features/social/presentation/pages/social_page.dart';
import '../../features/messages/presentation/pages/chat_page.dart';
import '../../features/messages/presentation/pages/conversations_page.dart';
import '../../features/moderation/domain/entities/report_target.dart';
import '../../features/moderation/presentation/pages/report_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/invite_friends_page.dart';
import '../../features/membership/presentation/pages/premium_membership_page.dart';
import '../../features/profile/presentation/pages/cfc_purchase_page.dart';
import '../../features/profile/presentation/pages/jeton_purchase_page.dart';
import '../../features/wallet/presentation/pages/wallet_center_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/user_profile_page.dart';
import '../../features/shell/presentation/main_shell_page.dart';
import '../../features/live/domain/entities/voice_room_entity.dart';
import '../../features/voice_hub/presentation/voice_room_route_page.dart';
import '../../features/voice_hub/presentation/voice_room_rtc_page.dart';
import '../../features/voice_hub/presentation/voice_rooms_hub_page.dart';
import '../../core/navigation/app_page_transitions.dart';

class RouterRefresh extends ChangeNotifier {
  RouterRefresh(this._ref) {
    _ref.listen<AsyncValue<dynamic>>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefresh(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final auth = ref.read(authControllerProvider);

      if (loc == '/splash') {
        if (auth.isLoading) return null;
        return auth.valueOrNull != null ? '/feed' : '/login';
      }

      final authed = auth.valueOrNull != null;
      final publicAuthPages = loc == '/login' ||
          loc == '/register' ||
          loc.startsWith('/auth/forgot-password') ||
          loc == '/auth/otp-verify';
      final canlifalWeb = loc == '/canlifal-web';
      if (!authed && !publicAuthPages && !canlifalWeb) return '/login';
      if (authed && publicAuthPages) return '/feed';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: '/auth/otp-verify',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: OtpVerifyPage(
            email: state.extra as String?,
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const SocialPage(),
                routes: [
                  GoRoute(
                    path: 'create',
                    pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
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
                builder: (context, state) => const LivePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/fortune',
                builder: (context, state) => const FortuneTarotHubPage(),
                routes: [
                  GoRoute(
                    path: ':slug',
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
                    routes: [
                      GoRoute(
                        path: 'result',
                        pageBuilder: (context, state) {
                          final result = state.extra as FortuneReadingResult?;
                          final child = result == null
                              ? const FortuneTarotHubPage()
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
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/live/prep',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const LiveBroadcastPrepPage(),
        ),
      ),
      GoRoute(
        path: '/live/room',
        pageBuilder: (context, state) {
          final session = state.extra as LiveBroadcastSession?;
          final child = session == null
              ? const LiveBroadcastPrepPage()
              : LiveBroadcastRoomPage(session: session);
          return AppPageTransitions.fadeSlide(
            key: state.pageKey,
            child: child,
          );
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
        path: '/user/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return UserProfilePage(userId: id);
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
          return AppPageTransitions.fadeSlide(
            key: state.pageKey,
            child: child,
          );
        },
      ),
      GoRoute(
        path: '/canlifal-web',
        builder: (context, state) => CanlifalWebRoute.fromState(state),
      ),
      GoRoute(
        path: '/voice-rooms',
        builder: (context, state) => const VoiceRoomsHubPage(),
      ),
      GoRoute(
        path: '/voice-room/:id',
        builder: (context, state) {
          final room = state.extra as VoiceRoomEntity?;
          if (room != null) {
            return VoiceRoomRtcPage(room: room);
          }
          final id = state.pathParameters['id'] ?? '';
          return VoiceRoomRoutePage(roomId: id);
        },
      ),
    ],
  );
});
