import 'package:equatable/equatable.dart';

class LiveStreamEntity extends Equatable {
  const LiveStreamEntity({
    required this.id,
    required this.title,
    this.streamerName,
    this.thumbnailUrl,
    this.viewerCount = 0,
    this.isLive = true,
  });

  final String id;
  final String title;
  final String? streamerName;
  final String? thumbnailUrl;
  final int viewerCount;
  final bool isLive;

  @override
  List<Object?> get props =>
      [id, title, streamerName, thumbnailUrl, viewerCount, isLive];
}
