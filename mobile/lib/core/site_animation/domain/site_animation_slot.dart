/// Kullanıcıya atanabilir animasyon slotları — runtime resolver.
enum SiteAnimationSlot {
  entrance,
  exit,
  profile,
  profileFrame,
  avatar,
  seat,
  mic,
  vip,
  gift;

  static SiteAnimationSlot? parse(String? raw) {
    final k = raw?.toLowerCase().trim() ?? '';
    return switch (k) {
      'entrance' => SiteAnimationSlot.entrance,
      'exit' => SiteAnimationSlot.exit,
      'profile' => SiteAnimationSlot.profile,
      'profileframe' || 'profile_frame' => SiteAnimationSlot.profileFrame,
      'avatar' => SiteAnimationSlot.avatar,
      'seat' => SiteAnimationSlot.seat,
      'mic' => SiteAnimationSlot.mic,
      'vip' => SiteAnimationSlot.vip,
      'gift' => SiteAnimationSlot.gift,
      _ => null,
    };
  }
}
