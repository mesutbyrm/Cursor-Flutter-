import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message_entities.dart';
import '../../domain/repositories/messages_repository.dart';
import '../../data/datasources/messages_remote_datasource.dart';
import '../../data/repositories/messages_repository_impl.dart';

export 'messages_unread_providers.dart';
export 'messages_mark_read_providers.dart';

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

/// Gelen kutusunda bekleyen mesaj istekleri.
final pendingMessageRequestsProvider =
    FutureProvider<List<MessageRequestEntity>>((ref) async {
  return ref.watch(messagesRepositoryProvider).pendingMessageRequests();
});

/// Bekleyen bir mesaj isteğini kabul/ret eder ve listeleri tazeler.
Future<void> respondToMessageRequest(
  WidgetRef ref,
  String requestId, {
  required bool accept,
}) async {
  final userId = ref.read(authControllerProvider).valueOrNull?.id;
  await ref.read(messagesRepositoryProvider).respondMessageRequest(
        requestId,
        accept: accept,
        currentUserId: userId,
      );
  ref.invalidate(pendingMessageRequestsProvider);
  ref.invalidate(conversationsProvider);
}

final chatMessagesProvider =
    FutureProvider.family<List<MessageEntity>, String>((ref, id) async {
  final userId = ref.watch(authControllerProvider).valueOrNull?.id;
  return ref.watch(messagesRepositoryProvider).messages(
        id,
        currentUserId: userId,
      );
});

