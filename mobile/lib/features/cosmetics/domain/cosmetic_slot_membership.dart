import '../../../core/membership/membership_capability_keys.dart';
import 'cosmetic_slot.dart';

extension CosmeticSlotMembership on CosmeticSlot {
  /// Admin `membership_features.key` — rozet hariç tier rozeti kullanır.
  String? get membershipCapabilityKey => switch (this) {
        CosmeticSlot.profileFrame => MembershipCapabilityKeys.profileFrame,
        CosmeticSlot.nameEffect => MembershipCapabilityKeys.nameEffect,
        CosmeticSlot.profileEffect => MembershipCapabilityKeys.seatEffect,
        CosmeticSlot.avatarAccessory => MembershipCapabilityKeys.profileFrame,
        CosmeticSlot.chatBubble => MembershipCapabilityKeys.messageBubble,
        CosmeticSlot.entranceAnimation => MembershipCapabilityKeys.entranceEffect,
        CosmeticSlot.microphoneFrame => MembershipCapabilityKeys.seatEffect,
        CosmeticSlot.badge => null,
      };
}
