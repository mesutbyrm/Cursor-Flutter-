import 'live_stream_entity.dart';

/// Yayın hazırlığından odaya aktarılan veri.
class LiveBroadcastSession {
  const LiveBroadcastSession({
    required this.title,
    required this.category,
    this.tags = const [],
    this.description = '',
    this.isHost = true,
    this.streamId,
    this.streamerName,
    this.streamerHandle,
    this.avatarUrl,
    this.viewerCount = 0,
  });

  final String title;
  final String category;
  final List<String> tags;
  final String description;
  final bool isHost;
  final String? streamId;
  final String? streamerName;
  final String? streamerHandle;
  final String? avatarUrl;
  final int viewerCount;

  factory LiveBroadcastSession.fromStream(LiveStreamEntity stream) {
    return LiveBroadcastSession(
      title: stream.title,
      category: 'Sohbet',
      isHost: false,
      streamId: stream.id,
      streamerName: stream.streamerName ?? 'Yayıncı',
      streamerHandle: 'yayinci',
      viewerCount: stream.viewerCount,
    );
  }

  factory LiveBroadcastSession.demoHost({
    required String title,
    required String category,
    List<String> tags = const [],
    String description = '',
    String? streamerName,
    String? streamerHandle,
    String? avatarUrl,
  }) {
    return LiveBroadcastSession(
      title: title,
      category: category,
      tags: tags,
      description: description,
      isHost: true,
      streamId: 'local-${DateTime.now().millisecondsSinceEpoch}',
      streamerName: streamerName ?? 'Cemre',
      streamerHandle: streamerHandle ?? 'cemreofficial',
      avatarUrl: avatarUrl,
    );
  }
}
