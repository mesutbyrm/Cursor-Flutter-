import 'package:go_router/go_router.dart';

import 'pages/agency_growth_pages.dart';
import 'pages/dream_community_pages.dart';
import 'pages/game_pages.dart';
import 'pages/leaderboard_page.dart';
import 'pages/membership_pages.dart';
import 'pages/refund_page.dart';
import 'pages/support_pages.dart';
import 'pages/teller_chat_pages.dart';
import 'pages/teller_pages.dart';

/// Web paritesi ekranlarının rotaları (üst düzey).
final List<RouteBase> webParityRoutes = [
  GoRoute(
    path: '/destek',
    builder: (context, state) => const SupportTicketsPage(),
  ),
  GoRoute(
    path: '/destek/yeni',
    builder: (context, state) => const SupportCreatePage(),
  ),
  GoRoute(
    path: '/destek/:id',
    builder: (context, state) =>
        SupportDetailPage(ticketId: state.pathParameters['id'] ?? ''),
  ),
  GoRoute(
    path: '/iade',
    builder: (context, state) => const RefundPage(),
  ),
  GoRoute(
    path: '/uyelik/hediye',
    builder: (context, state) => const MembershipGiftPage(),
  ),
  GoRoute(
    path: '/uyelik/karsilastir',
    builder: (context, state) => const MembershipComparisonPage(),
  ),
  GoRoute(
    path: '/liderlik',
    builder: (context, state) => const LeaderboardsPage(),
  ),
  GoRoute(
    path: '/falci-paneli',
    builder: (context, state) => const TellerPanelPage(),
  ),
  GoRoute(
    path: '/falci-sohbet',
    builder: (context, state) => const TellerChatListPage(),
  ),
  GoRoute(
    path: '/falci-sohbet/:id',
    builder: (context, state) =>
        TellerChatThreadPage(sessionId: state.pathParameters['id'] ?? ''),
  ),
  GoRoute(
    path: '/ajans/buyume',
    builder: (context, state) => const AgencyGrowthPage(),
  ),
  GoRoute(
    path: '/ajans/basvuran-skoru/:userId',
    builder: (context, state) =>
        ApplicantScorePage(userId: state.pathParameters['userId'] ?? ''),
  ),
  GoRoute(
    path: '/ruya/trendler',
    builder: (context, state) => const DreamTrendsPage(),
  ),
  GoRoute(
    path: '/ruya/uret',
    builder: (context, state) => const DreamGeneratePage(),
  ),
  GoRoute(
    path: '/ruya/:slug/yorumlar',
    builder: (context, state) =>
        DreamCommentsPage(slug: state.pathParameters['slug'] ?? ''),
  ),
  GoRoute(
    path: '/oyunlar/lamba-cini',
    builder: (context, state) => const LambaCiniPage(),
  ),
  GoRoute(
    path: '/oyunlar/lobi',
    builder: (context, state) => const GamesLobbyPage(),
  ),
];
