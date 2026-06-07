class HomeTrendVideoEntity {
  const HomeTrendVideoEntity({
    required this.id,
    required this.title,
    required this.channelName,
    this.thumbnailUrl,
    this.duration = '',
    this.badge,
    this.viewCount = 0,
  });

  final String id;
  final String title;
  final String channelName;
  final String? thumbnailUrl;
  final String duration;
  final String? badge;
  final int viewCount;
}
