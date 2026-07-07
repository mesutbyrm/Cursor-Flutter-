import 'package:flutter/material.dart';

import 'voice_rooms_fx.dart';
import 'voice_rooms_mock_data.dart';
import 'voice_rooms_ui_tokens.dart';

class TrendingTopicsCard extends StatelessWidget {
  const TrendingTopicsCard({super.key, required this.topics});

  final List<TrendingTopicItem> topics;

  @override
  Widget build(BuildContext context) {
    return VoiceGlassFxContainer(
      radius: VoiceRoomsUiTokens.radiusLg,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      glowColor: VoiceRoomsUiTokens.magenta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Trend Konular',
            style: TextStyle(
              color: VoiceRoomsUiTokens.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...topics.map(
            (topic) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.tag,
                            style: const TextStyle(
                              color: VoiceRoomsUiTokens.purpleGlow,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          topic.views,
                          style: const TextStyle(
                            color: VoiceRoomsUiTokens.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
