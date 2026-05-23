import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message_entities.dart';
import '../../domain/repositories/messages_repository.dart';
import '../../data/datasources/messages_remote_datasource.dart';
import '../../data/repositories/messages_repository_impl.dart';

final messagesRemoteProvider = Provider<MessagesRemoteDataSource>((ref) {
  return MessagesRemoteDataSource(ref.watch(dioProvider));
});

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepositoryImpl(ref.watch(messagesRemoteProvider));
});

final conversationsProvider =
    FutureProvider<List<ConversationEntity>>((ref) async {
  return ref.watch(messagesRepositoryProvider).conversations();
});

final chatMessagesProvider =
    FutureProvider.family<List<MessageEntity>, String>((ref, id) async {
  final userId = ref.watch(authControllerProvider).valueOrNull?.id;
  return ref.watch(messagesRepositoryProvider).messages(
        id,
        currentUserId: userId,
      );
});

/// Tüm sohbetlerdeki okunmamış mesaj toplamı (alt bar rozeti).
final messagesUnreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(conversationsProvider);
  return list.maybeWhen(
    data: (items) =>
        items.fold<int>(0, (sum, c) => sum + c.unreadCount),
    orElse: () => 0,
  );
});
