class HomeTrendVideoEntity {
  const HomeTrendVideoEntity({
    required this.id,
    required this.title,
    required this.channelName,
    this.thumbnailUrl,
    this.duration = '',
    this.badge,
    this.viewCount = 0,
    this.videoUrl,
  });

  final String id;
  final String title;
  final String channelName;
  final String? thumbnailUrl;
  final String duration;
  final String? badge;
  final int viewCount;
  /// CDN MP4 — kısa video akışına yönlendirme için.
  final String? videoUrl;

  bool get isYoutubeSource {
    final hay = '${videoUrl ?? ''} ${thumbnailUrl ?? ''} ${title.toLowerCase()}';
    return hay.contains('youtube') ||
        hay.contains('youtu.be') ||
        hay.contains('googlevideo');
  }
}
