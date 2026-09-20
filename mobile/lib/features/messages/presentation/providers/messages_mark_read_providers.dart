import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import 'conversations_list_notifier.dart';
import 'messages_providers.dart';

Future<void> markAllMessagesRead(WidgetRef ref) async {
  final userId = ref.read(authControllerProvider).valueOrNull?.id;
  ref.read(conversationsListNotifierProvider.notifier).markAllReadLocally();
  await ref.read(messagesRepositoryProvider).markAllConversationsRead(
        currentUserId: userId,
      );
  await ref.read(conversationsListNotifierProvider.notifier).refresh(
        forceRefresh: true,
        silent: true,
      );
  ref.invalidate(conversationsProvider);
  ref.invalidate(notificationsUnreadApiProvider);
}
