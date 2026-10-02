import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/messages/data/models/conversation_dto.dart';
import 'package:canlifal_social/features/messages/domain/entities/message_entities.dart';
import 'package:canlifal_social/features/messages/domain/repositories/messages_repository.dart';
import 'package:canlifal_social/features/messages/presentation/providers/conversations_list_notifier.dart';
import 'package:canlifal_social/features/messages/presentation/providers/messages_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth extends AuthController {
  @override
  Future<UserEntity?> build() async =>
      const UserEntity(id: 'me', username: 'me', displayName: 'me');
}

class _Repo implements MessagesRepository {
  List<ConversationEntity> server = [];

  @override
  Future<List<ConversationEntity>> conversations({
    bool forceRefresh = false,
    String? cacheUserId,
  }) async =>
      List.of(server);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('ConversationDto: backend üst düzey lastMessageAt okunur (sıralama/saat etiketi)', () {
    final dto = ConversationDto.fromApiMap({
      'id': 'conv-row-id',
      'user': {'id': 'peer1', 'name': 'Ayşe'},
      'lastMessage': 'selam',
      'lastMessageAt': '2026-10-02T10:30:00.000Z',
      'unreadCount': 2,
    });
    expect(dto.id, 'peer1', reason: 'sohbet kimliği karşı tarafın userId\'si');
    expect(dto.lastMessageAt, DateTime.utc(2026, 10, 2, 10, 30));
    expect(dto.unreadCount, 2);
  });

  test('yerelde okundu işaretlenen sohbet, bayat sunucu listesinde tekrar okunmamış görünmez',
      () async {
    final repo = _Repo()
      ..server = [
        ConversationEntity(
          id: 'peer1',
          title: 'Ayşe',
          unreadCount: 3,
          lastMessageAt: DateTime.utc(2026, 10, 2, 10, 0),
        ),
      ];
    final c = ProviderContainer(
      overrides: [
        messagesRepositoryProvider.overrideWithValue(repo),
        authControllerProvider.overrideWith(_FakeAuth.new),
      ],
    );
    addTearDown(c.dispose);
    final sub = c.listen(conversationsListNotifierProvider, (_, __) {});
    addTearDown(sub.close);
    await c.read(conversationsListNotifierProvider.future);
    expect(c.read(conversationsListNotifierProvider).requireValue.all.single.unreadCount, 3);

    final n = c.read(conversationsListNotifierProvider.notifier);
    n.markConversationReadLocally('peer1');
    expect(c.read(conversationsListNotifierProvider).requireValue.all.single.unreadCount, 0);

    // Sunucu henüz "okundu"yu işlemedi: yenileme yine 3 döndürür.
    await n.refresh(silent: true, forceRefresh: true);
    expect(c.read(conversationsListNotifierProvider).requireValue.all.single.unreadCount, 0);

    // Karşı taraf SONRA yeni mesaj yazarsa sayaç yeniden görünür.
    repo.server = [
      ConversationEntity(
        id: 'peer1',
        title: 'Ayşe',
        unreadCount: 1,
        lastMessageAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
      ),
    ];
    await n.refresh(silent: true, forceRefresh: true);
    expect(c.read(conversationsListNotifierProvider).requireValue.all.single.unreadCount, 1);
  });
}
