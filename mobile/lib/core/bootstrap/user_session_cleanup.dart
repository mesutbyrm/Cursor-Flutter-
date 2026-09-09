import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/economy/presentation/providers/economy_providers.dart';
import '../../features/fortune/presentation/providers/fortune_api_providers.dart';
import '../../features/fortune/presentation/providers/fortune_hub_providers.dart';
import '../../features/games/presentation/providers/game_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/home/data/datasources/mobile_compound_remote_datasource.dart';
import '../../features/home/presentation/providers/home_providers.dart';
import '../../features/messages/data/hidden_conversations_store.dart';
import '../../features/messages/data/deleted_messages_store.dart';
import '../../features/messages/presentation/providers/conversations_list_notifier.dart';
import '../../features/messages/presentation/providers/messages_providers.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/presentation/providers/notifications_list_notifier.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../features/social/presentation/providers/social_providers.dart';
import '../network/sse/sse_hub_provider.dart';
import '../network/user_online_presence_provider.dart';
import 'session_data_refresh.dart';

/// Logout / kullanıcı değişiminde SSE + oturum provider temizliği.
Future<void> invalidateUserSessionCaches(
  Ref ref, {
  String? userId,
  bool skipPresenceHeartbeat = false,
}) async {
  invalidateAuthenticatedShellData(
    ref,
    skipPresenceHeartbeat: skipPresenceHeartbeat,
  );

  final hub = ref.read(sseConnectionHubProvider);
  await hub.dispose();

  ref.invalidate(sseConnectionHubProvider);
  ref.invalidate(notificationsListProvider);
  ref.invalidate(notificationsListNotifierProvider);
  ref.invalidate(notificationsUnreadApiProvider);
  ref.invalidate(conversationsProvider);
  ref.invalidate(conversationsListNotifierProvider);
  ref.invalidate(homeGamesProvider);
  ref.invalidate(homeDailyRewardsProvider);
  ref.invalidate(homeVoiceRoomsProvider);
  ref.invalidate(gameCatalogProvider);
  ref.invalidate(gameRoomsProvider);
  ref.invalidate(socialNotifierProvider);
  ref.invalidate(mobileCompoundRemoteProvider);
  ref.invalidate(fortuneHistoryProvider);
  ref.invalidate(fortuneDailyInsightsProvider);
  ref.invalidate(fortuneHubPreferencesStoreProvider);
  ref.invalidate(userDailyTasksProvider);
  ref.invalidate(economyWalletProvider);

  await NotificationsRepositoryImpl.clearLocalReadState();
  if (userId != null && userId.isNotEmpty) {
    try {
      final store = await ref.read(fortuneHubPreferencesStoreProvider.future);
      await store.clear();
    } catch (_) {}
  }
  if (userId != null && userId.isNotEmpty) {
    await HiddenConversationsStore.clearForUser(userId);
    await DeletedMessagesStore.clearForUser(userId);
  }
}

/// Auth logout — SSE hub + TRTC singleton state temizliği.
Future<void> teardownRealtimeOnLogout(Ref ref, {String? userId}) async {
  await ref.read(userOnlinePresenceProvider.notifier).leave();
  await invalidateUserSessionCaches(
    ref,
    userId: userId,
    skipPresenceHeartbeat: true,
  );
  ref.invalidate(userOnlinePresenceProvider);
}
