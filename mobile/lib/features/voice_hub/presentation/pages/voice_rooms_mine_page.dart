import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/presentation/providers/live_providers.dart';
import '../utils/open_voice_chat_room_flow.dart';
import '../widgets/voice_rooms_ui/voice_rooms_ui.dart';
import 'voice_rooms_page.dart' show VoiceRoomsStaticBackground;

/// Odalarım — sahip olunan odalar, ayarlar ve yeni oda aç.
class VoiceRoomsMinePage extends ConsumerWidget {
  const VoiceRoomsMinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(myOwnedVoiceRoomsProvider);
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: VoiceRoomsUiTokens.bgAmoled,
      ),
      child: Scaffold(
        backgroundColor: VoiceRoomsUiTokens.bgAmoled,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const VoiceRoomsStaticBackground(),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      VoiceRoomsHeaderBar(
                        showBack: true,
                        title: 'Odalarım',
                        subtitle: owned.isEmpty
                            ? 'Henüz odan yok'
                            : '${owned.length} açık oda',
                        showTrophy: false,
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            VoiceRoomsUiTokens.padScreenH,
                            12,
                            VoiceRoomsUiTokens.padScreenH,
                            24,
                          ),
                          children: [
                            if (owned.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.mic_none_rounded,
                                      size: 56,
                                      color: VoiceRoomsUiTokens.textMuted,
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      'Henüz bir odan yok',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Odanı aç, arkadaşlarını davet et.',
                                      style: TextStyle(
                                        color:
                                            VoiceRoomsUiTokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              for (final room in owned)
                                OwnedRoomRow(room: room),
                            const SizedBox(height: 6),
                            VrPressable(
                              semanticLabel: 'Yeni oda aç',
                              onTap: () => showOpenVoiceChatRoomFlow(context, ref),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: VoiceRoomsUiTokens.purpleGradient,
                                  borderRadius: BorderRadius.circular(
                                    VoiceRoomsUiTokens.radiusPill,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_rounded,
                                        color: Colors.white, size: 21),
                                    SizedBox(width: 6),
                                    Text(
                                      'Yeni Oda Aç',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
