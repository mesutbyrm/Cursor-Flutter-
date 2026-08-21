import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/games/presentation/providers/game_providers.dart';
import '../../features/home/presentation/providers/home_providers.dart';
import '../../features/messages/data/hidden_conversations_store.dart';
import '../../features/messages/data/deleted_messages_store.dart';
import '../../features/messages/presentation/providers/conversations_list_notifier.dart';
import '../../features/messages/presentation/providers/messages_providers.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/presentation/providers/notifications_list_notifier.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../features/social/presentation/providers/social_providers.dart';
import 'session_data_refresh.dart';

/// Logout veya kullanıcı değişiminde oturuma bağlı provider/cache temizliği.
Future<void> invalidateUserSessionCaches(Ref ref, {String? userId}) async {
  invalidateAuthenticatedShellData(ref);

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

  await NotificationsRepositoryImpl.clearLocalReadState();
  if (userId != null && userId.isNotEmpty) {
    await HiddenConversationsStore.clearForUser(userId);
    await DeletedMessagesStore.clearForUser(userId);
  }
}
