import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_page_transitions.dart';

import '../../content_detail/presentation/pages/blog_post_page.dart';
import '../../content_detail/presentation/pages/blog_zodiac_page.dart';
import '../../content_detail/presentation/pages/dream_symbol_page.dart';
import '../../content_detail/presentation/pages/tiktok_videos_page.dart';
import '../../games/presentation/pages/sos_game_page.dart';

import 'pages/agency_growth_pages.dart';
import 'pages/contact_page.dart';
import 'pages/dream_community_pages.dart';
import 'pages/feature_hub_page.dart';
import 'pages/game_pages.dart';
import 'pages/leaderboard_page.dart';
import 'pages/membership_pages.dart';
import 'pages/refund_page.dart';
import 'pages/support_pages.dart';
import 'pages/teller_chat_pages.dart';
import 'pages/teller_pages.dart';

/// Web paritesi ekranlarının rotaları (üst düzey).
final List<RouteBase> webParityRoutes = [
  // İçerik detayları — web yollarıyla aynı (`/blog/burclar` slug'dan önce).
  GoRoute(
    path: '/blog/burclar',
    builder: (context, state) =>
        BlogZodiacPage(initialSign: state.uri.queryParameters['burc']),
  ),
  GoRoute(
    path: '/blog/:slug',
    builder: (context, state) =>
        BlogPostPage(slug: state.pathParameters['slug'] ?? ''),
  ),
  GoRoute(
    path: '/ruya-sozlugu/:slug',
    builder: (context, state) =>
        DreamSymbolPage(slug: state.pathParameters['slug'] ?? ''),
  ),
  GoRoute(
    path: '/games-sos/:id',
    builder: (context, state) =>
        SosGamePage(gameId: state.pathParameters['id'] ?? ''),
  ),
  GoRoute(
    path: '/tiktok',
    builder: (context, state) => const TiktokVideosPage(),
  ),
  GoRoute(
    path: '/tiktok/:id',
    builder: (context, state) =>
        TiktokVideoPage(id: state.pathParameters['id'] ?? ''),
  ),
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
  GoRoute(
    path: '/ozellikler',
    // Animasyon pilotu: `animations` shared-axis geçişi.
    pageBuilder: (context, state) => AppPageTransitions.premiumAxis(
      key: state.pageKey,
      child: const FeatureHubPage(),
    ),
  ),
  GoRoute(
    path: '/iletisim',
    builder: (context, state) => const ContactPage(),
  ),
];
