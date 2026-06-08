import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../theme/voice_room_tokens.dart';

/// Tasarım referansı alt bar — mesaj, gönder, hediye + jeton satırı.
class VoiceRoomSpecFooter extends StatelessWidget {
  const VoiceRoomSpecFooter({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.coinBalance,
    required this.sending,
    required this.onSend,
    required this.onRefresh,
    required this.onShare,
    required this.onTopUp,
    this.onGiftTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int coinBalance;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onRefresh;
  final VoidCallback onShare;
  final VoidCallback onTopUp;
  final VoidCallback? onGiftTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, bottom + 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.88),
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
                  onPressed: () {},
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: 22,
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
                        horizontal: 16,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: VoiceRoomTokens.neonPurple,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: sending ? null : onSend,
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: sending
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
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
                      width: 42,
                      height: 42,
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        color: AppThemeColors.coinGold,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.diamond_rounded,
                  size: 14,
                  color: AppThemeColors.diamondBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatCoins(coinBalance),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: AppThemeColors.diamondBlue,
                  ),
                ),
                const Spacer(),
                _FooterPill(
                  icon: Icons.refresh_rounded,
                  label: 'Yenile',
                  onTap: onRefresh,
                ),
                const SizedBox(width: 8),
                _FooterPill(
                  icon: Icons.share_rounded,
                  label: 'Paylaş',
                  onTap: onShare,
                ),
                const SizedBox(width: 8),
                Material(
                  color: VoiceRoomTokens.neonPurple,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onTopUp,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Jeton Yükle',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _FooterPill extends StatelessWidget {
  const _FooterPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
