import 'package:flutter/material.dart';

/// Benzersiz Hero tag üretici — avatar, profil, gönderi, shorts çakışmasını önler.
abstract final class HeroTags {
  static String avatar(String userId) => 'hero_avatar_$userId';
  static String profileBanner(String userId) => 'hero_profile_banner_$userId';
  static String postImage(String postId) => 'hero_post_$postId';
  static String shortThumb(String videoId) => 'hero_short_$videoId';
}

/// Avatar Hero sarmalayıcı.
class HeroAvatar extends StatelessWidget {
  const HeroAvatar({
    super.key,
    required this.userId,
    required this.child,
  });

  final String userId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (userId.trim().isEmpty) return child;
    return Hero(tag: HeroTags.avatar(userId), child: child);
  }
}

/// Gönderi görseli Hero sarmalayıcı.
class HeroPostImage extends StatelessWidget {
  const HeroPostImage({
    super.key,
    required this.postId,
    required this.child,
  });

  final String postId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (postId.trim().isEmpty) return child;
    return Hero(tag: HeroTags.postImage(postId), child: child);
  }
}

/// Kısa video kapak Hero sarmalayıcı — grid/keşfet → feed geçişi.
class HeroShortThumb extends StatelessWidget {
  const HeroShortThumb({
    super.key,
    required this.videoId,
    required this.child,
  });

  final String videoId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (videoId.trim().isEmpty) return child;
    return Hero(
      tag: HeroTags.shortThumb(videoId),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
