import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_page_transitions.dart';
import '../domain/entities/pf_coffee_reading.dart';
import '../domain/entities/pf_dream_reading.dart';
import '../domain/entities/pf_tarot_reading.dart';
import '../presentation/astrology/pf_astrology_page.dart';
import '../presentation/auth/pf_auth_page.dart';
import '../presentation/chat/pf_chat_page.dart';
import '../presentation/coffee/pf_coffee_page.dart';
import '../presentation/dreams/pf_dreams_page.dart';
import '../presentation/games/pf_games_page.dart';
import '../presentation/home/pf_home_page.dart';
import '../presentation/live/pf_live_tellers_page.dart';
import '../presentation/profile/pf_profile_page.dart';
import '../presentation/shell/pf_shell_page.dart';
import '../presentation/tarot/pf_tarot_page.dart';
import '../presentation/wallet/pf_wallet_page.dart';

/// Premium Fortune modülü rotaları.
List<RouteBase> get premiumFortuneRoutes => [
      GoRoute(
        path: '/premium/auth',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PfAuthPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => PfShellPage(child: child),
        routes: [
          GoRoute(
            path: '/premium',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const PfHomePage(),
            ),
          ),
          GoRoute(
            path: '/premium/live',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const PfLiveTellersPage(),
            ),
            routes: [
              GoRoute(
                path: ':tellerId',
                pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
                  key: state.pageKey,
                  child: PfTellerDetailPage(
                    tellerId: state.pathParameters['tellerId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/premium/chat',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const PfChatListPage(),
            ),
            routes: [
              GoRoute(
                path: ':conversationId',
                pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
                  key: state.pageKey,
                  child: PfChatRoomPage(
                    conversationId: state.pathParameters['conversationId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/premium/wallet',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const PfWalletPage(),
            ),
          ),
          GoRoute(
            path: '/premium/profile',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const PfProfilePage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/premium/coffee',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PfCoffeePage(),
        ),
        routes: [
          GoRoute(
            path: 'result',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: PfCoffeeResultPage(
                reading: state.extra as PfCoffeeReading,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/premium/tarot',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PfTarotPage(),
        ),
        routes: [
          GoRoute(
            path: 'result',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: PfTarotResultPage(
                reading: state.extra as PfTarotReading,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/premium/astrology',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PfAstrologyPage(),
        ),
      ),
      GoRoute(
        path: '/premium/dreams',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PfDreamsPage(),
        ),
        routes: [
          GoRoute(
            path: 'result',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: PfDreamResultPage(
                reading: state.extra as PfDreamReading,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/premium/games',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PfGamesPage(),
        ),
      ),
      GoRoute(
        path: '/premium/admin',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const PfAdminPage(),
        ),
      ),
    ];
