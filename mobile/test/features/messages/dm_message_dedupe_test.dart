import 'package:canlifal_social/features/messages/domain/entities/message_entities.dart';
import 'package:canlifal_social/features/messages/domain/utils/dm_message_dedupe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merge removes duplicate remote messageId', () {
    final now = DateTime(2026, 1, 1, 12);
    final remote = [
      MessageEntity(id: 'm1', text: 'hello', isMine: false, createdAt: now),
      MessageEntity(id: 'm1', text: 'hello', isMine: false, createdAt: now),
      MessageEntity(id: 'm2', text: 'world', isMine: true, createdAt: now),
    ];

    final merged = DmMessageDedupe.merge(remote: remote);
    expect(merged.length, 2);
    expect(merged.map((m) => m.id).toList(), ['m1', 'm2']);
  });

  test('merge keeps optimistic local until remote reconcile', () {
    final now = DateTime(2026, 1, 1, 12);
    final remote = [
      MessageEntity(id: 'm1', text: 'hi', isMine: true, createdAt: now),
    ];
    final optimistic = [
      MessageEntity(
        id: 'local-1',
        text: 'pending',
        isMine: true,
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    ];

    final merged = DmMessageDedupe.merge(
      remote: remote,
      localOptimistic: optimistic,
    );
    expect(merged.length, 2);
    expect(merged.any((m) => m.id == 'local-1'), isTrue);
  });

  test('merge drops optimistic when remote duplicate text matches', () {
    final now = DateTime(2026, 1, 1, 12);
    final remote = [
      MessageEntity(id: 'm9', text: 'same', isMine: true, createdAt: now),
    ];
    final optimistic = [
      MessageEntity(
        id: 'local-9',
        text: 'same',
        isMine: true,
        createdAt: now,
      ),
    ];

    final merged = DmMessageDedupe.merge(
      remote: remote,
      localOptimistic: optimistic,
    );
    expect(merged.length, 1);
    expect(merged.first.id, 'm9');
  });
}
