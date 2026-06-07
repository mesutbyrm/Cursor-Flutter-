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
      ];
}
