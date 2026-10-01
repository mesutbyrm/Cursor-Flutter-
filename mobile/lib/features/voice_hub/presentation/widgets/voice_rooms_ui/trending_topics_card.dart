import 'package:flutter/material.dart';

import 'voice_rooms_mock_data.dart';
import 'voice_rooms_ui_tokens.dart';

Color _vrRankColor(int rank) => switch (rank) {
      1 => VoiceRoomsUiTokens.gold,
      2 => VoiceRoomsUiTokens.purpleGlow,
      3 => VoiceRoomsUiTokens.blue,
      4 => VoiceRoomsUiTokens.onlineGreen,
      _ => VoiceRoomsUiTokens.magenta,
    };

/// Trend konular — sıra rozetli liste (veri: trend API).
class TrendingTopicsCard extends StatelessWidget {
  const TrendingTopicsCard({super.key, required this.topics});

  final List<TrendingTopicItem> topics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1252), Color(0xFF150A2B)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.25),
                ),
                child: const Icon(Icons.tag_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'Trend Konular',
                style: TextStyle(
                  color: VoiceRoomsUiTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < topics.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _vrRankColor(i + 1),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i == 0 ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      topics[i].tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB388FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    topics[i].views,
                    style: const TextStyle(
                      color: VoiceRoomsUiTokens.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
