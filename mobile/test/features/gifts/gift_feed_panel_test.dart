import 'package:canlifal_social/features/gifts/domain/gift_engine_models.dart';
import 'package:canlifal_social/features/gifts/presentation/engine/gift_feed_panel.dart';
import 'package:flutter_test/flutter_test.dart';

GiftFeedItem _i(String id, String s, String g, int combo) => GiftFeedItem(
      id: id,
      senderName: s,
      giftName: g,
      jetonAmount: 10,
      combo: combo,
      expiresAt: DateTime(2030),
    );

void main() {
  test('aynı gönderen + hediye tek satırda toplanır', () {
    final rows = mergeGiftFeedItems([
      _i('3', 'Mert', 'Aslan', 3),
      _i('2', 'Mert', 'Aslan', 2),
      _i('1', 'Mert', 'Aslan', 1),
      _i('0', 'Ayşe', 'Kalp', 1),
    ]);
    expect(rows, hasLength(2));
    expect(rows.first.count, 6);
    expect(rows.first.senderName, 'Mert');
    expect(rows.last.giftName, 'Kalp');
  });

  test('farklı hediye ayrı satır; combo 0/1 en az 1 sayılır', () {
    final rows = mergeGiftFeedItems([
      _i('2', 'Mert', 'Aslan', 0),
      _i('1', 'Mert', 'Şato', 1),
    ]);
    expect(rows, hasLength(2));
    expect(rows.first.count, 1);
  });
}
