import 'dart:async';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/messages/domain/entities/message_entities.dart';
import 'package:canlifal_social/features/messages/domain/repositories/messages_repository.dart';
import 'package:canlifal_social/features/messages/domain/utils/dm_message_merge.dart';
import 'package:canlifal_social/features/messages/presentation/providers/chat_messages_list_notifier.dart';
import 'package:canlifal_social/features/messages/presentation/providers/messages_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 10, 2, 12, 0, 0);

MessageEntity _m(
  String id,
  String text, {
  bool mine = false,
  int sec = 0,
  MessageDeliveryStatus status = MessageDeliveryStatus.sent,
}) =>
    MessageEntity(
      id: id,
      text: text,
      isMine: mine,
      createdAt: _t0.add(Duration(seconds: sec)),
      deliveryStatus: status,
    );

class _FakeAuth extends AuthController {
  @override
  Future<UserEntity?> build() async =>
      const UserEntity(id: 'me', username: 'me', displayName: 'me');
}

class _FakeRepo implements MessagesRepository {
  Completer<List<MessageEntity>>? pending;
  List<MessageEntity> server = [];
  int sent = 0;
  bool failFetch = false;

  @override
  Future<List<MessageEntity>> messages(
    String conversationId, {
    String? currentUserId,
    bool forceRefresh = false,
  }) {
    if (failFetch) return Future.error(Exception('ağ'));
    final p = pending;
    if (p != null) return p.future;
    return Future.value(List.of(server));
  }

  @override
  Future<void> sendMessage(
    String conversationId,
    String text, {
    String? currentUserId,
    String? replyId,
    String? replyText,
    bool forward = false,
    String? forwardFrom,
  }) async {
    sent++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DmMessageMerge.mergeById', () {
    test('sunucuda olmayan optimistic mesaj korunur (ezilmez)', () {
      final out = DmMessageMerge.mergeById(
        previous: [_m('a', 'eski', sec: 0), _m('local-1', 'merhaba', mine: true, sec: 30)],
        remote: [_m('a', 'eski', sec: 0)],
      );
      expect(out.map((m) => m.text), ['eski', 'merhaba']);
    });

    test('sunucuda eşi gelince optimistic yerini sunucu mesajı alır (tekrar yok)', () {
      final out = DmMessageMerge.mergeById(
        previous: [_m('local-1', 'merhaba', mine: true, sec: 30)],
        remote: [_m('srv-9', 'merhaba', mine: true, sec: 31)],
      );
      expect(out, hasLength(1));
      expect(out.single.id, 'srv-9');
    });

    test('sunucu sayfa sınırı: listedeki en yeniden DAHA YENİ mesaj korunur', () {
      final out = DmMessageMerge.mergeById(
        previous: [_m('srv-1', 'ilk', sec: 0), _m('srv-200', 'yeni', sec: 500)],
        remote: [_m('srv-1', 'ilk', sec: 0)], // arka uç yalnızca en eski 100'ü döndürür
      );
      expect(out.map((m) => m.id), ['srv-1', 'srv-200']);
    });

    test('aynı kimlikte sunucu sürümü kazanır', () {
      final out = DmMessageMerge.mergeById(
        previous: [_m('srv-1', 'x', mine: true, status: MessageDeliveryStatus.sending)],
        remote: [_m('srv-1', 'x', mine: true, status: MessageDeliveryStatus.delivered)],
      );
      expect(out.single.deliveryStatus, MessageDeliveryStatus.delivered);
    });

    test('upsert: SSE mesajı optimistic olanın yerini alır, diğerlerine dokunmaz', () {
      final cur = [_m('srv-1', 'a', sec: 0), _m('local-2', 'selam', mine: true, sec: 10)];
      final out = DmMessageMerge.upsert(cur, _m('srv-2', 'selam', mine: true, sec: 11));
      expect(out.map((m) => m.id), ['srv-1', 'srv-2']);
    });
  });

  group('ChatMessagesListNotifier — yenileme sürerken gönderilen mesaj kaybolmaz', () {
    test('GET gönderimden önce başlayıp gönderimden sonra biterse mesaj korunur', () async {
      final repo = _FakeRepo()..server = [_m('srv-1', 'eski', sec: 0)];
      final c = ProviderContainer(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(repo),
          authControllerProvider.overrideWith(_FakeAuth.new),
        ],
      );
      addTearDown(c.dispose);
      final p = chatMessagesListNotifierProvider('peer');
      final sub = c.listen(p, (_, __) {});
      addTearDown(sub.close);
      await c.read(p.future);

      // 1) Bayat bir yenileme başlar (sunucu cevabı gecikir).
      final stale = Completer<List<MessageEntity>>();
      repo.pending = stale;
      final refreshing = c.read(p.notifier).refresh(silent: true);

      // 2) Bu sırada kullanıcı mesaj gönderir (optimistic eklenir).
      repo.pending = null;
      await c.read(p.notifier).sendMessage(text: 'merhaba', currentUserId: 'me');
      expect(c.read(p).requireValue.all.any((m) => m.text == 'merhaba'), isTrue);

      // 3) Gecikmiş GET, gönderimi İÇERMEYEN eski listeyle biter.
      stale.complete([_m('srv-1', 'eski', sec: 0)]);
      await refreshing;

      final texts = c.read(p).requireValue.all.map((m) => m.text).toList();
      expect(texts, contains('merhaba'),
          reason: 'bayat yanıt, gönderilen mesajı ezmemeli (3–5 sn sonra kayboluyordu)');
      expect(texts, contains('eski'));
    });

    test('sessiz yenileme hata verirse ekrandaki mesajlar korunur', () async {
      final repo = _FakeRepo()..server = [_m('srv-1', 'eski', sec: 0)];
      final c = ProviderContainer(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(repo),
          authControllerProvider.overrideWith(_FakeAuth.new),
        ],
      );
      addTearDown(c.dispose);
      final p = chatMessagesListNotifierProvider('peer');
      final sub = c.listen(p, (_, __) {});
      addTearDown(sub.close);
      await c.read(p.future);

      repo.failFetch = true;
      await c.read(p.notifier).refresh(silent: true);
      final s = c.read(p);
      expect(s.hasError, isFalse);
      expect(s.requireValue.all.map((m) => m.text), ['eski']);
    });
  });
}
