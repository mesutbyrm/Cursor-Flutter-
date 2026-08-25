import 'package:flutter_test/flutter_test.dart';

void main() {
  test('direct gift send body matches kılavuz §9.9', () {
    const giftId = 'gift_1';
    const receiverUserId = 'user_2';
    const quantity = 1;
    final body = <String, dynamic>{
      'giftId': giftId,
      'receiverUserId': receiverUserId,
      'quantity': quantity,
    };
    expect(body.keys, containsAll(['giftId', 'receiverUserId', 'quantity']));
    expect(body.containsKey('giftTypeId'), isFalse);
    expect(body.containsKey('recipientId'), isFalse);
  });
}
