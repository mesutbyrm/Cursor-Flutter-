import 'package:canlifal_social/core/membership/membership_capability_keys.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_slot.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_slot_membership.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cosmetic slots map to membership capability keys', () {
    expect(
      CosmeticSlot.chatBubble.membershipCapabilityKey,
      MembershipCapabilityKeys.messageBubble,
    );
    expect(CosmeticSlot.badge.membershipCapabilityKey, isNull);
  });
}
