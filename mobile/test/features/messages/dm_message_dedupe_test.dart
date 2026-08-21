import 'package:canlifal_social/features/messages/domain/entities/message_entities.dart';
import 'package:canlifal_social/features/messages/domain/utils/dm_message_dedupe.dart';
import 'package:flutter_test/flutter_test.dart';

MessageEntity _msg(String id, String text) => MessageEntity(
      id: id,
      text: text,
      isMine: false,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  test('dedupeMessagesById keeps first occurrence', () {
    final out = dedupeMessagesById([
      _msg('m1', 'a'),
      _msg('m1', 'dup'),
      _msg('m2', 'b'),
    ]);
    expect(out.length, 2);
    expect(out.first.text, 'a');
  });

  test('dedupeMessagesById preserves empty-id optimistic rows', () {
    final out = dedupeMessagesById([
      _msg('', 'pending'),
      _msg('m1', 'ok'),
    ]);
    expect(out.length, 2);
  });
}
