import 'package:flutter/material.dart';

/// Yayın videosu yüklenirken / uzak yayıncı yokken arka plan.
class LiveRoomVideoBackground extends StatelessWidget {
  const LiveRoomVideoBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2A1848),
                Color(0xFF120A1C),
                Color(0xFF0A0818),
              ],
            ),
          ),
        ),
        Center(
          child: Icon(
            Icons.videocam_rounded,
            size: 100,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0, 0.35, 1],
            ),
          ),
        ),
      ],
    );
  }
}
