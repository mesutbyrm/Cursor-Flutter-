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
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottom + 8),
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
              width: 52,
              height: 52,
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
                size: item.danger ? 26 : 24,
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

/// Sohbet girişi — kompakt, video üzerinde.
class LivePkChatInputBar extends StatelessWidget {
  const LivePkChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onToggleVisibility,
    this.onGift,
    this.onQuickRose,
    this.onMore,
    this.visible = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onGift;
  final VoidCallback? onQuickRose;
  final VoidCallback? onMore;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(24),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Mesajını yaz...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  prefixIcon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.white.withValues(alpha: 0.55),
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, color: Colors.white),
          ),
          if (onQuickRose != null)
            IconButton(
              onPressed: onQuickRose,
              tooltip: 'Gül',
              icon: const Text('🌹', style: TextStyle(fontSize: 20)),
            ),
          if (onGift != null)
            IconButton(
              onPressed: onGift,
              tooltip: 'Hediye',
              icon: const Icon(Icons.card_giftcard_rounded,
                  color: Color(0xFFFFD54F)),
            ),
          if (onMore != null)
            IconButton(
              onPressed: onMore,
              tooltip: 'Daha fazla',
              icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
            ),
        ],
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
