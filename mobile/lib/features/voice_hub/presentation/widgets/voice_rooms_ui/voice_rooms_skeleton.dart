import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'voice_rooms_ui_tokens.dart';

class VoiceRoomsCategorySkeleton extends StatelessWidget {
  const VoiceRoomsCategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: VoiceRoomsUiTokens.padScreenH),
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: VoiceRoomsUiTokens.gapMd),
        itemBuilder: (_, _) => Column(
          children: [
            _shimmerBox(52, 52, radius: 26),
            const SizedBox(height: 6),
            _shimmerBox(40, 10, radius: 6),
          ],
        ),
      ),
    );
  }
}

class VoiceRoomsFeaturedSkeleton extends StatelessWidget {
  const VoiceRoomsFeaturedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = ((width - 40) / 2).clamp(160.0, 280.0);
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: VoiceRoomsUiTokens.padScreenH),
        itemCount: 2,
        separatorBuilder: (_, _) => const SizedBox(width: VoiceRoomsUiTokens.gapMd),
        itemBuilder: (_, _) => _shimmerBox(cardWidth, 148, radius: VoiceRoomsUiTokens.radiusLg),
      ),
    );
  }
}

class VoiceRoomsPopularSkeleton extends StatelessWidget {
  const VoiceRoomsPopularSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VoiceRoomsUiTokens.padScreenH,
            VoiceRoomsUiTokens.gapLg,
            VoiceRoomsUiTokens.padScreenH,
            VoiceRoomsUiTokens.gapSm,
          ),
          child: _shimmerBox(180, 16, radius: 8),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: VoiceRoomsUiTokens.padScreenH),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: VoiceRoomsUiTokens.gapMd),
            itemBuilder: (_, _) => _shimmerBox(168, 210, radius: VoiceRoomsUiTokens.radiusLg),
          ),
        ),
      ],
    );
  }
}

class VoiceRoomsNearbySkeleton extends StatelessWidget {
  const VoiceRoomsNearbySkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VoiceRoomsUiTokens.padScreenH),
      child: Column(
        children: List.generate(
          count,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: VoiceRoomsUiTokens.gapMd),
            child: _shimmerBox(double.infinity, 88, radius: VoiceRoomsUiTokens.radiusMd),
          ),
        ),
      ),
    );
  }
}

class VoiceRoomsSidebarSkeleton extends StatelessWidget {
  const VoiceRoomsSidebarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VoiceRoomsUiTokens.padScreenH),
      child: Column(
        children: [
          _shimmerBox(double.infinity, 180, radius: VoiceRoomsUiTokens.radiusLg),
          const SizedBox(height: VoiceRoomsUiTokens.gapMd),
          _shimmerBox(double.infinity, 160, radius: VoiceRoomsUiTokens.radiusLg),
          const SizedBox(height: VoiceRoomsUiTokens.gapMd),
          _shimmerBox(double.infinity, 200, radius: VoiceRoomsUiTokens.radiusLg),
        ],
      ),
    );
  }
}

Widget _shimmerBox(double width, double height, {double radius = 12}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: const Color(0xFF141414),
    ),
  )
      .animate(onPlay: (c) => c.repeat())
      .shimmer(
        duration: 1400.ms,
        color: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.14),
      );
}
