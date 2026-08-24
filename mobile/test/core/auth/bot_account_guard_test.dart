import 'package:canlifal_social/core/auth/bot_account_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJsonMap detects isBot and role', () {
    expect(BotAccountGuard.fromJsonMap({'isBot': true}), isTrue);
    expect(BotAccountGuard.fromJsonMap({'role': 'bot'}), isTrue);
    expect(BotAccountGuard.fromJsonMap({'accountType': 'bot'}), isTrue);
    expect(BotAccountGuard.fromJsonMap({'roles': ['moderator_bot']}), isTrue);
    expect(BotAccountGuard.fromJsonMap({'role': 'user'}), isFalse);
  });
}
