import '../domain/site_animation_command.dart';

class SiteAnimationState {
  const SiteAnimationState({
    this.active,
    this.seatTransition,
    this.queueLength = 0,
    this.preloading = false,
  });

  final SiteAnimationCommand? active;
  final SiteAnimationCommand? seatTransition;
  final int queueLength;
  final bool preloading;

  SiteAnimationState copyWith({
    SiteAnimationCommand? active,
    SiteAnimationCommand? seatTransition,
    int? queueLength,
    bool? preloading,
    bool clearActive = false,
    bool clearSeatTransition = false,
  }) {
    return SiteAnimationState(
      active: clearActive ? null : (active ?? this.active),
      seatTransition: clearSeatTransition
          ? null
          : (seatTransition ?? this.seatTransition),
      queueLength: queueLength ?? this.queueLength,
      preloading: preloading ?? this.preloading,
    );
  }
}
