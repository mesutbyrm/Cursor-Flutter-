/// Backend site animation olay türleri.
enum SiteAnimationType {
  memberJoined,
  memberLeft,
  seatChanged,
  micEnabled,
  micDisabled,
  hostSeat,
  seatRankGlow,
}

extension SiteAnimationTypeX on SiteAnimationType {
  bool get isEntrance =>
      this == SiteAnimationType.memberJoined ||
      this == SiteAnimationType.hostSeat;

  bool get isExit => this == SiteAnimationType.memberLeft;

  bool get isSeatAnchored =>
      this == SiteAnimationType.seatChanged ||
      this == SiteAnimationType.seatRankGlow ||
      this == SiteAnimationType.hostSeat ||
      this == SiteAnimationType.micEnabled ||
      this == SiteAnimationType.micDisabled;
}
