import 'live_stream_entity.dart';

/// Dikey swipe canlı yayın akışı argümanları.
class LiveSwipeFeedArgs {
  const LiveSwipeFeedArgs({
    required this.streams,
    this.initialIndex = 0,
  });

  final List<LiveStreamEntity> streams;
  final int initialIndex;
}
