import 'package:flutter/material.dart';

@immutable
class PremiumVoiceRoomSphere {
  const PremiumVoiceRoomSphere({
    required this.name,
    required this.participants,
    required this.centerIcon,
    required this.glowColors,
    required this.avatarUrls,
  });

  final String name;
  final int participants;
  final IconData centerIcon;
  final List<Color> glowColors;
  final List<String> avatarUrls;
}
