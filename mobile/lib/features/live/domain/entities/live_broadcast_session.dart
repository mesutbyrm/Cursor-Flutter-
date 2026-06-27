import 'live_stream_entity.dart';
import 'live_guest_layout.dart';
import '../../../agora/domain/entities/agora_credentials.dart';
import '../../../trtc/domain/entities/trtc_credentials.dart';

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
    this.trtc,
    this.agora,
    this.hostUserId,
    this.initialMicOn = true,
    this.initialCameraOn = true,
    this.isImageMode = false,
    this.coverImageUrl,
    this.backgroundUrl,
    this.playbackUrl,
    this.guestLayout = LiveGuestLayout.solo,
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
  final TrtcCredentials? trtc;
  final AgoraCredentials? agora;
  final String? hostUserId;
  final bool initialMicOn;
  final bool initialCameraOn;
  final bool isImageMode;
  final String? coverImageUrl;
  final String? backgroundUrl;
  /// HLS köprüsü — Agora ilk kare gelene kadar.
  final String? playbackUrl;
  final LiveGuestLayout guestLayout;

  factory LiveBroadcastSession.fromStream(LiveStreamEntity stream) {
    final category = stream.category?.trim().isNotEmpty == true
        ? stream.category!.trim()
        : (stream.isFortuneStream ? 'fortune' : 'chat');
    return LiveBroadcastSession(
      title: stream.title,
      category: category,
      tags: stream.tags,
      isHost: false,
      streamId: stream.id,
      streamerName: stream.streamerName ?? 'Yayıncı',
      streamerHandle: 'yayinci',
      avatarUrl: stream.thumbnailUrl,
      viewerCount: stream.viewerCount,
      trtc: null,
      hostUserId: stream.hostUserId,
      coverImageUrl: stream.thumbnailUrl,
      playbackUrl: stream.playbackUrl,
    );
  }

  LiveBroadcastSession copyWith({
    String? title,
    String? category,
    List<String>? tags,
    String? streamId,
    TrtcCredentials? trtc,
    AgoraCredentials? agora,
    String? hostUserId,
    bool? initialMicOn,
    bool? initialCameraOn,
    int? viewerCount,
    bool? isImageMode,
    String? coverImageUrl,
    String? backgroundUrl,
    String? playbackUrl,
    LiveGuestLayout? guestLayout,
  }) {
    return LiveBroadcastSession(
      title: title ?? this.title,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      description: description,
      isHost: isHost,
      streamId: streamId ?? this.streamId,
      streamerName: streamerName,
      streamerHandle: streamerHandle,
      avatarUrl: avatarUrl,
      viewerCount: viewerCount ?? this.viewerCount,
      trtc: trtc ?? this.trtc,
      agora: agora ?? this.agora,
      hostUserId: hostUserId ?? this.hostUserId,
      initialMicOn: initialMicOn ?? this.initialMicOn,
      initialCameraOn: initialCameraOn ?? this.initialCameraOn,
      isImageMode: isImageMode ?? this.isImageMode,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      playbackUrl: playbackUrl ?? this.playbackUrl,
      guestLayout: guestLayout ?? this.guestLayout,
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
    bool isImageMode = false,
    String? coverImageUrl,
    String? backgroundUrl,
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
      isImageMode: isImageMode,
      coverImageUrl: coverImageUrl,
      backgroundUrl: backgroundUrl,
      trtc: null,
    );
  }
}
