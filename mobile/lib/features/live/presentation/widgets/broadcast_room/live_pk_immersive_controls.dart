import 'package:flutter/material.dart';

import '../../../../voice_hub/presentation/theme/voice_room_tokens.dart';

class LivePkControlItem {
  const LivePkControlItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = true,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool danger;
}

/// Alt overlay — yuvarlak şeffaf butonlar (mikrofon, kamera, rakip ses, sohbet, bitir).
class LivePkImmersiveControls extends StatelessWidget {
  const LivePkImmersiveControls({
    super.key,
    required this.items,
  });

  final List<LivePkControlItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final item in items) _RoundControl(item: item),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.item});

  final LivePkControlItem item;

  @override
  Widget build(BuildContext context) {
    final disabled = item.onTap == null;
    final bg = item.danger
        ? const Color(0xFFE53935)
        : Colors.black.withValues(alpha: 0.45);
    final iconColor = item.active
        ? Colors.white
        : Colors.white.withValues(alpha: 0.45);

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: Border.all(
                  color: item.danger
                      ? Colors.redAccent.withValues(alpha: 0.6)
                      : VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
                ),
                boxShadow: item.active && !item.danger
                    ? VoiceRoomTokens.neonGlow(
                        VoiceRoomTokens.neonPurple,
                        blur: 10,
                      )
                    : null,
              ),
              child: Icon(
                item.danger ? Icons.stop_rounded : item.icon,
                color: item.danger ? Colors.white : iconColor,
                size: item.danger ? 22 : 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PK alt çubuğu (Bigo/TikTok): «Yorum yaz...» + Hediye + Paylaş.
class LivePkChatInputBar extends StatelessWidget {
  const LivePkChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onToggleVisibility,
    this.onGift,
    this.onShare,
    this.onQuickRose,
    this.onMore,
    this.visible = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onGift;
  final VoidCallback? onShare;
  final VoidCallback? onQuickRose;
  final VoidCallback? onMore;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Yorum yaz...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  // Gönder yalnız yazı varken görünür.
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, v, _) => v.text.trim().isEmpty
                        ? const SizedBox(width: 8)
                        : IconButton(
                            onPressed: onSend,
                            tooltip: 'Gönder',
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (onGift != null) ...[
            const SizedBox(width: 8),
            _BarAction(
              onTap: onGift!,
              label: 'Hediye',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4D8D), Color(0xFFB832FF)],
              ),
              icon: Icons.card_giftcard_rounded,
            ),
          ],
          if (onShare != null) ...[
            const SizedBox(width: 8),
            _BarAction(
              onTap: onShare!,
              label: 'Paylaş',
              icon: Icons.ios_share_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.onTap,
    required this.label,
    required this.icon,
    this.gradient,
  });

  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                color: gradient == null
                    ? Colors.black.withValues(alpha: 0.4)
                    : null,
                border: gradient == null
                    ? Border.all(color: Colors.white.withValues(alpha: 0.18))
                    : null,
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sağ kenar floating hediye — referans "Gönder".
class LivePkFloatingGiftButton extends StatelessWidget {
  const LivePkFloatingGiftButton({
    super.key,
    required this.onTap,
    this.bottom = 168,
  });

  final VoidCallback onTap;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: bottom,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌹', style: TextStyle(fontSize: 22)),
                Text(
                  'Gönder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
