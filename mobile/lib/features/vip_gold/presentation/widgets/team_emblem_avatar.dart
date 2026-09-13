import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entrance_theme.dart';

/// Takım amblemi — logo URL veya renkli monogram.
class TeamEmblemAvatar extends StatelessWidget {
  const TeamEmblemAvatar({
    super.key,
    required this.theme,
    this.size = 44,
  });

  final EntranceTheme theme;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = theme.logoUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.borderColor, width: 2),
          boxShadow: [
            BoxShadow(color: theme.glowColor, blurRadius: 10),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _monogram(),
          ),
        ),
      );
    }
    if (theme.flagEmoji != null && theme.flagEmoji!.isNotEmpty) {
      return Text(theme.flagEmoji!, style: TextStyle(fontSize: size * 0.9));
    }
    return _monogram();
  }

  Widget _monogram() {
    final label = theme.teamName?.trim() ?? '';
    final letter =
        label.isNotEmpty ? label.substring(0, 1).toUpperCase() : '⚽';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [theme.primary, theme.secondary],
        ),
        border: Border.all(color: theme.borderColor, width: 2),
        boxShadow: [
          BoxShadow(color: theme.glowColor, blurRadius: 12),
        ],
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
