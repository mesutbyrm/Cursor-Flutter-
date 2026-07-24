/// Kozmetik ekipman yuvası — backend `slot` alanı ile uyumlu.
enum CosmeticSlot {
  profileFrame,
  nameEffect,
  profileEffect,
  avatarAccessory,
  chatBubble,
  entranceAnimation,
  microphoneFrame,
  badge,
}

extension CosmeticSlotX on CosmeticSlot {
  String get apiKey => switch (this) {
        CosmeticSlot.profileFrame => 'profileFrame',
        CosmeticSlot.nameEffect => 'nameEffect',
        CosmeticSlot.profileEffect => 'profileEffect',
        CosmeticSlot.avatarAccessory => 'avatarAccessory',
        CosmeticSlot.chatBubble => 'chatBubble',
        CosmeticSlot.entranceAnimation => 'entranceAnimation',
        CosmeticSlot.microphoneFrame => 'microphoneFrame',
        CosmeticSlot.badge => 'badge',
      };

  String get labelTr => switch (this) {
        CosmeticSlot.profileFrame => 'Profil çerçevesi',
        CosmeticSlot.nameEffect => 'İsim efekti',
        CosmeticSlot.profileEffect => 'Profil efekti',
        CosmeticSlot.avatarAccessory => 'Avatar aksesuarı',
        CosmeticSlot.chatBubble => 'Sohbet balonu',
        CosmeticSlot.entranceAnimation => 'Giriş animasyonu',
        CosmeticSlot.microphoneFrame => 'Mikrofon çerçevesi',
        CosmeticSlot.badge => 'Rozet',
      };
}
