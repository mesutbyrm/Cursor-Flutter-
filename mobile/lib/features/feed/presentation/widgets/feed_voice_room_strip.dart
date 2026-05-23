import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class _Room {
  const _Room(this.name, this.icon, this.c1, this.c2);
  final String name;
  final IconData icon;
  final Color c1;
  final Color c2;
}

/// Her iki gönderiden sonra — hikâye şeridine benzeyen yatay 4 sesli oda.
class FeedVoiceRoomStrip extends StatelessWidget {
  const FeedVoiceRoomStrip({super.key});

  static const _rooms = [
    _Room(
      'Müzik Keyfi',
      Icons.mic_rounded,
      Color(0xFFFF2D7A),
      Color(0xFFB400FF),
    ),
    _Room(
      'Gece Sohbeti',
      Icons.chat_bubble_rounded,
      Color(0xFF4FACFE),
      Color(0xFF7B2CBF),
    ),
    _Room(
      'Yıldızların Altında',
      Icons.nightlight_round,
      Color(0xFFE040FB),
      Color(0xFFFFD166),
    ),
    _Room(
      'Kahve Molası',
      Icons.local_cafe_rounded,
      Color(0xFF8D5524),
      Color(0xFFFFC107),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sesli odalar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _rooms.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final r = _rooms[i];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            r.c1.withValues(alpha: 0.95),
                            r.c2.withValues(alpha: 0.55),
                            AppTheme.background,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: r.c1.withValues(alpha: 0.45),
                            blurRadius: 16,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(r.icon, color: Colors.white, size: 30),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.lightGreenAccent.shade400,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 80,
                      child: Text(
                        r.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
