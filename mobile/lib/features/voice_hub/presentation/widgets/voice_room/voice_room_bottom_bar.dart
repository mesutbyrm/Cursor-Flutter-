import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design.dart';

class VoiceRoomBottomBar extends StatelessWidget {
  const VoiceRoomBottomBar({
    super.key,
    required this.controller,
    required this.coinBalance,
    required this.micOn,
    required this.sending,
    required this.onSend,
    required this.onMicToggle,
    required this.onRefresh,
    required this.onShare,
    required this.onTopUp,
    this.onGiftTap,
  });

  final TextEditingController controller;
  final int coinBalance;
  final bool micOn;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onMicToggle;
  final VoidCallback onRefresh;
  final VoidCallback onShare;
  final VoidCallback onTopUp;
  final VoidCallback? onGiftTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, bottom + 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            border: Border(
              top: BorderSide(color: AppDesign.accentPurple.withValues(alpha: 0.35)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onMicToggle,
                    icon: Icon(
                      micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      color: micOn ? AppDesign.accentPink : AppDesign.textMuted,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        hintStyle: TextStyle(
                          color: AppDesign.textMuted.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  IconButton(
                    onPressed: sending ? null : onSend,
                    icon: Icon(
                      Icons.send_rounded,
                      color: sending
                          ? AppDesign.textMuted
                          : AppDesign.accentPurple,
                    ),
                  ),
                  IconButton(
                    onPressed: onGiftTap,
                    icon: const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppDesign.coinGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '💎 $coinBalance Jeton',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: AppDesign.diamondBlue,
                    ),
                  ),
                  const Spacer(),
                  _PillButton(
                    label: '🔄 Yenile',
                    onTap: onRefresh,
                  ),
                  const SizedBox(width: 8),
                  _PillButton(
                    label: '🔗 Paylaş',
                    onTap: onShare,
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppDesign.accentPurple,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: onTopUp,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          '🪙 Jeton Yükle',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
          ),
        ),
      ),
    );
  }
}
