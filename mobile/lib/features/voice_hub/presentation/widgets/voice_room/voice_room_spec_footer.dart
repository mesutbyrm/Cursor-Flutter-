import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../theme/voice_room_tokens.dart';

/// Alt bar — mesaj satırı + ana sayfa / hoparlör / mikrofon / ayarlar / jeton.
class VoiceRoomSpecFooter extends StatelessWidget {
  const VoiceRoomSpecFooter({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.coinBalance,
    required this.onSend,
    required this.onHome,
    required this.onToggleAudioOutput,
    required this.headphonesOn,
    required this.onMicToggle,
    required this.micOn,
    required this.micEnabled,
    required this.onRoomSettings,
    required this.onUserSettings,
    required this.onTopUp,
    this.onGiftTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int coinBalance;
  final VoidCallback onSend;
  final VoidCallback onHome;
  final VoidCallback onToggleAudioOutput;
  final bool headphonesOn;
  final VoidCallback onMicToggle;
  final bool micOn;
  final bool micEnabled;
  final VoidCallback onRoomSettings;
  final VoidCallback onUserSettings;
  final VoidCallback onTopUp;
  final VoidCallback? onGiftTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 6, 10, bottom + 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.92),
          border: Border(
            top: BorderSide(
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {},
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(
                        color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                          color: VoiceRoomTokens.neonPurple,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: VoiceRoomTokens.neonPurple,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onSend,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: AppThemeColors.coinGold.withValues(alpha: 0.18),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onGiftTap,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        color: AppThemeColors.coinGold,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _IconAction(
                    icon: Icons.home_rounded,
                    label: 'Ana Sayfa',
                    onTap: onHome,
                  ),
                ),
                Expanded(
                  child: _IconAction(
                    icon: headphonesOn
                        ? Icons.headphones_rounded
                        : Icons.volume_up_rounded,
                    label: headphonesOn ? 'Kulaklık' : 'Hoparlör',
                    onTap: onToggleAudioOutput,
                    active: headphonesOn,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Material(
                      color: micOn
                          ? VoiceRoomTokens.neonPurple
                          : Colors.white.withValues(alpha: 0.12),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: micEnabled ? onMicToggle : null,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                            color: micEnabled
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _IconAction(
                    icon: Icons.meeting_room_rounded,
                    label: 'Oda',
                    onTap: onRoomSettings,
                  ),
                ),
                Expanded(
                  child: _IconAction(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    onTap: onUserSettings,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatCoins(coinBalance),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          color: AppThemeColors.diamondBlue,
                        ),
                      ),
                      Material(
                        color: VoiceRoomTokens.neonPurple,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: onTopUp,
                          borderRadius: BorderRadius.circular(14),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            child: Text(
                              'Jeton Yükle',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCoins(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
        buf.write(s[i]);
      }
      return '${buf.toString()} Jeton';
    }
    return '$n Jeton';
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? VoiceRoomTokens.neonPurple : Colors.white70,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: active
                    ? VoiceRoomTokens.neonPurple
                    : Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
