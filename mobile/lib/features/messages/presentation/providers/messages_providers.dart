import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
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
  return ref.watch(messagesRepositoryProvider).messages(id);
});
