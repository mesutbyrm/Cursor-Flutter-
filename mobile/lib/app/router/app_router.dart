import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../screens/premium_home/premium_home_screen.dart';
import '../../features/live/presentation/pages/live_page.dart';
import '../../features/social/presentation/pages/social_page.dart';
import '../../features/messages/presentation/pages/chat_page.dart';
import '../../features/messages/presentation/pages/conversations_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/invite_friends_page.dart';
import '../../features/profile/presentation/pages/jeton_purchase_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/user_profile_page.dart';
import '../../features/shell/presentation/main_shell_page.dart';
import '../../features/voice_hub/presentation/voice_rooms_hub_page.dart';

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
      final publicAuthPages = loc == '/login' || loc == '/register';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              // Ana sayfa (Keşfet): PremiumHomeScreen — mockup ile hizalı.
              GoRoute(
                path: '/feed',
                builder: (context, state) => const PremiumHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const SocialPage(),
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
                path: '/messages',
                builder: (context, state) => const ConversationsPage(),
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
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/jeton-store',
        builder: (context, state) => const JetonPurchasePage(),
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
        path: '/canlifal-web',
        builder: (context, state) => CanlifalWebRoute.fromState(state),
      ),
      GoRoute(
        path: '/voice-rooms',
        builder: (context, state) => const VoiceRoomsHubPage(),
      ),
    ],
  );
});
