import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../features/admin/presentation/pages/admin_hub_page.dart';
import '../../features/fortune/presentation/pages/fortune_tarot_hub_page.dart';
import '../../features/fortune/presentation/pages/fortune_types_all_page.dart';
import '../../features/games/presentation/game_center/pages/game_center_leaderboard_page.dart';
import '../../features/games/presentation/game_center/pages/game_center_page.dart';
import '../../features/games/presentation/game_center/pages/game_play_pages.dart';
import '../../features/games/presentation/pages/game_room_page.dart';
import '../../features/games/presentation/pages/games_hub_page.dart';
import '../../features/gifts/presentation/pages/gift_send_page.dart';
import '../../features/live/domain/entities/live_broadcast_session.dart';
import '../../features/live/presentation/pages/live_broadcast_prep_page.dart';
import '../../features/live/domain/entities/live_swipe_feed_args.dart';
import '../../features/live/presentation/pages/live_broadcast_room_page.dart';
import '../../features/live/presentation/pages/live_page.dart';
import '../../features/live/presentation/pages/live_swipe_viewer_page.dart';
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
import '../../features/profile/presentation/pages/profile_about_page.dart';
import '../../features/profile/presentation/pages/profile_account_security_page.dart';
import '../../features/profile/presentation/pages/profile_broadcast_history_page.dart';
import '../../features/profile/presentation/pages/profile_broadcaster_stats_page.dart';
import '../../features/profile/presentation/pages/profile_earnings_page.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/profile/presentation/pages/profile_equipment_page.dart';
import '../../features/profile/presentation/pages/profile_follow_list_page.dart';
import '../../features/profile/presentation/pages/profile_gifts_page.dart';
import '../../features/profile/presentation/pages/growth_hub_page.dart';
import '../../features/profile/presentation/pages/profile_help_support_page.dart';
import '../../features/profile/presentation/pages/profile_payment_notice_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
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
import '../../features/voice_hub/presentation/voice_room_rtc_page.dart';
import '../../features/voice_hub/presentation/widgets/voice_room_error_boundary.dart';
import '../../features/voice_hub/presentation/voice_rooms_hub_page.dart';
import '../../features/home/presentation/pages/live_fortune_teller_detail_page.dart';
import '../../features/home/presentation/pages/live_fortune_session_page.dart';
import '../../features/home/presentation/pages/live_fortune_tellers_page.dart';
import '../../features/home/domain/entities/live_fortune_session_entity.dart';
import '../../features/vip_gold/presentation/pages/vip_gold_hub_page.dart';
import '../../core/bootstrap/app_startup_log.dart';
import '../../core/bootstrap/auth_redirect.dart';
import '../../core/bootstrap/startup_route_observer.dart';
import '../../core/navigation/app_page_transitions.dart';

/// Misafir modu değişince redirect yeniden değerlendirilir.
class RouterAuthRefresh extends ChangeNotifier {
  RouterAuthRefresh(Ref ref) {
    ref.listen<bool>(guestModeProvider, (prev, next) {
      if (prev != next) _notifyOnce();
    });
  }

  void _notifyOnce() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }
}

/// Çıkış / misafir geçişinde go_router sıfırdan.

/// Push / global modal sheet'ler için kök navigator.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Giriş, çıkış veya misafir geçişinde go_router sıfırdan.
final shellSessionProvider = StateProvider<int>((ref) => 0);

final goRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(shellSessionProvider);
  final authRefresh = RouterAuthRefresh(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/feed',
    observers: [StartupRouteObserver()],
    refreshListenable: authRefresh,
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
        redirect: (context, state) => '/feed',
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
        path: '/profile/edit',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
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
        path: '/profile/growth',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const GrowthHubPage(),
        ),
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
        path: '/games-hub',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const GameCenterPage(),
        ),
        routes: [
          GoRoute(
            path: 'leaderboard',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const GameCenterLeaderboardPage(),
            ),
          ),
          GoRoute(
            path: 'wheel',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const WheelOfFortunePage(),
            ),
          ),
          GoRoute(
            path: 'quiz',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const QuizGamePage(),
            ),
          ),
          GoRoute(
            path: 'word-duel',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const WordDuelPage(),
            ),
          ),
          GoRoute(
            path: 'love-match',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const LoveMatchPage(),
            ),
          ),
          GoRoute(
            path: 'backgammon',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const BackgammonPage(),
            ),
          ),
          GoRoute(
            path: 'live-quiz',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const LiveQuizRoomPage(),
            ),
          ),
          GoRoute(
            path: 'pk-prediction',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const PkPredictionPage(),
            ),
          ),
          GoRoute(
            path: 'bingo',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const LiveBingoPage(),
            ),
          ),
          GoRoute(
            path: 'treasure',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const TreasureChestPage(),
            ),
          ),
          GoRoute(
            path: 'lucky-dice',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const LuckyDicePage(),
            ),
          ),
          GoRoute(
            path: 'lobby',
            pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
              key: state.pageKey,
              child: const GamesHubPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/games-room/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final title = state.uri.queryParameters['title'];
          return AppPageTransitions.fadeSlide(
            key: state.pageKey,
            child: GameRoomPage(roomId: id, title: title),
          );
        },
      ),
      GoRoute(
        path: '/dreams-hub',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const NativeFeatureHubPage(kind: NativeFeatureHubKind.dreams),
        ),
      ),
      GoRoute(
        path: '/blog-hub',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const NativeFeatureHubPage(kind: NativeFeatureHubKind.blog),
        ),
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
        path: '/canli-falcilar',
        pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
          key: state.pageKey,
          child: const LiveFortuneTellersPage(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return AppPageTransitions.fadeSlide(
                key: state.pageKey,
                child: LiveFortuneTellerDetailPage(tellerId: id),
              );
            },
            routes: [
              GoRoute(
                path: 'session',
                pageBuilder: (context, state) {
                  final session = state.extra as LiveFortuneSessionEntity?;
                  if (session == null) {
                    final id = state.pathParameters['id'] ?? '';
                    return AppPageTransitions.fadeSlide(
                      key: state.pageKey,
                      child: LiveFortuneTellerDetailPage(tellerId: id),
                    );
                  }
                  return AppPageTransitions.fadeSlide(
                    key: state.pageKey,
                    child: LiveFortuneSessionPage(session: session),
                  );
                },
              ),
            ],
          ),
        ],
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
            final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
            return VoiceRoomErrorBoundary(
              roomId: key,
              child: VoiceRoomRtcPage(room: room),
            );
          }
          final id = state.pathParameters['id'] ?? '';
          return VoiceRoomRoutePage(roomId: id);
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
