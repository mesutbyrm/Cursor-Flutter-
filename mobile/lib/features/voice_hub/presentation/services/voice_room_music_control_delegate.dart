/// Bildirim ve sistem medya kontrolleri → oda DJ API / yerel oynatıcı.
class VoiceRoomMusicControlDelegate {
  const VoiceRoomMusicControlDelegate({
    this.onPlay,
    this.onPause,
    this.onStop,
    this.onSkipToNext,
    this.onSkipToPrevious,
    this.syncServerControls = false,
  });

  final Future<void> Function()? onPlay;
  final Future<void> Function()? onPause;
  final Future<void> Function()? onStop;
  final Future<void> Function()? onSkipToNext;
  final Future<void> Function()? onSkipToPrevious;

  /// true → play/pause/stop bildirimde sunucu DJ uçlarına gider.
  final bool syncServerControls;
}
