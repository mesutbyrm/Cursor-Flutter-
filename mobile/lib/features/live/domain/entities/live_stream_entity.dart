import 'package:equatable/equatable.dart';

class LiveStreamEntity extends Equatable {
  const LiveStreamEntity({
    required this.id,
    required this.title,
    this.streamerName,
    this.thumbnailUrl,
    this.category,
    this.viewerCount = 0,
    this.isLive = true,
    this.hostUserId,
    this.playbackUrl,
    this.tags = const [],
    this.isPkLive = false,
    this.isVipHost = false,
  });

  final String id;
  final String title;
  final String? streamerName;
  final String? thumbnailUrl;
  final String? category;
  final int viewerCount;
  final bool isLive;
  /// Yayıncının TRTC / kullanıcı kimliği (`user.id` from API).
  final String? hostUserId;
  /// HLS / playback URL — ana sayfa canlı önizleme.
  final String? playbackUrl;
  final List<String> tags;
  final bool isPkLive;
  final bool isVipHost;

  bool get isFortuneStream {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('fortune') || cat.contains('fal')) return true;
    return tags.any((t) {
      final l = t.toLowerCase();
      return l.contains('fal') || l.contains('tarot') || l.contains('fortune');
    });
  }

  @override
  List<Object?> get props => [
        id,
        title,
        streamerName,
        thumbnailUrl,
        category,
        viewerCount,
        isLive,
        hostUserId,
        playbackUrl,
        tags,
        isPkLive,
        isVipHost,
      ];
}
