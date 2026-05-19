import 'package:flutter/foundation.dart';

/// Üst şerit — mockup’taki yuvarlak hikâye / canlı önizleme halkaları.
@immutable
class PremiumStoryTrayItem {
  const PremiumStoryTrayItem({
    required this.id,
    required this.label,
    required this.avatarUrl,
    this.isAddStory = false,
    this.hasNew = false,
    this.isLive = false,
  });

  final String id;
  final String label;
  final String avatarUrl;
  final bool isAddStory;
  final bool hasNew;
  final bool isLive;
}
