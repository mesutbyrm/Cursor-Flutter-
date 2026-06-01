import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../profile/presentation/widgets/premium/profile_glass.dart';

/// Web sesli oda koltuk düzeni (8 koltuk + merkez sahne).
class VoiceRoomSeatGrid extends StatelessWidget {
  const VoiceRoomSeatGrid({
    super.key,
    required this.roomIcon,
    required this.roomName,
    this.backgroundUrl,
    this.centerAvatarUrl,
    this.recentAvatars = const [],
    this.speakingUserIndex,
  });

  final String roomIcon;
  final String roomName;
  final String? backgroundUrl;
  final String? centerAvatarUrl;
  final List<String> recentAvatars;
  final int? speakingUserIndex;

  static const _seatCount = 8;

  @override
  Widget build(BuildContext context) {
    final seats = List<String?>.generate(_seatCount, (i) {
      if (i < recentAvatars.length) return recentAvatars[i];
      return null;
    });

    return Stack(
      fit: StackFit.expand,
      children: [
        if (backgroundUrl != null && backgroundUrl!.isNotEmpty)
          CachedNetworkImage(imageUrl: backgroundUrl!, fit: BoxFit.cover)
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E1848), Color(0xFF0A0818)],
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ..._seatPositions().entries.map((e) {
                      final idx = e.key;
                      final pos = e.value;
                      return Align(
                        alignment: pos,
                        child: _SeatBubble(
                          avatarUrl: seats[idx],
                          speaking: speakingUserIndex == idx,
                          label: seats[idx] != null ? null : 'Boş',
                        ),
                      );
                    }),
                    _CenterStage(
                      icon: roomIcon,
                      name: roomName,
                      avatarUrl: centerAvatarUrl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<int, Alignment> _seatPositions() {
    return const {
      0: Alignment(-0.95, -0.85),
      1: Alignment(0.95, -0.85),
      2: Alignment(-1.0, -0.15),
      3: Alignment(1.0, -0.15),
      4: Alignment(-1.0, 0.55),
      5: Alignment(1.0, 0.55),
      6: Alignment(-0.85, 0.95),
      7: Alignment(0.85, 0.95),
    };
  }
}

class _CenterStage extends StatelessWidget {
  const _CenterStage({
    required this.icon,
    required this.name,
    this.avatarUrl,
  });

  final String icon;
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: 999,
      blur: 14,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: context.colors.brandGradient,
              boxShadow: AppThemeColors.glowShadow(AppThemeColors.accentPink, blur: 24),
            ),
            child: avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(child: Text(icon, style: const TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Sesli sohbet',
            style: TextStyle(
              color: AppThemeColors.accentCyan.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.04, 1.04),
          duration: 2200.ms,
        );
  }
}

class _SeatBubble extends StatelessWidget {
  const _SeatBubble({
    this.avatarUrl,
    this.speaking = false,
    this.label,
  });

  final String? avatarUrl;
  final bool speaking;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final glow = speaking ? AppThemeColors.accentPink : AppThemeColors.accentPurple;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: glow.withValues(alpha: speaking ? 1 : 0.4),
              width: speaking ? 3 : 1.5,
            ),
            boxShadow: speaking ? AppThemeColors.glowShadow(glow, blur: 14) : null,
            color: Colors.black.withValues(alpha: 0.35),
          ),
          child: avatarUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.add_rounded,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: TextStyle(fontSize: 9, color: context.colors.onSurfaceMuted),
          ),
        ],
      ],
    );
  }
}
