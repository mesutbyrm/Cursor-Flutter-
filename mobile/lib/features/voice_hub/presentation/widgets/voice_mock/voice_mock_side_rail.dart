import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Sağ kenar hızlı düğmeler — Hediye · Müzik · PK · İstek · Daha Fazla.
class VoiceMockSideRail extends StatelessWidget {
  const VoiceMockSideRail({
    super.key,
    required this.onGift,
    required this.onMusic,
    required this.onPk,
    required this.onRequest,
    required this.onMore,
    this.requestPending = false,
    this.topSlot,
  });

  final VoidCallback onGift;
  final VoidCallback onMusic;
  final VoidCallback onPk;
  final VoidCallback onRequest;
  final VoidCallback onMore;
  final bool requestPending;

  /// Yarışma kutuları düğmelerin üstünde durur.
  final Widget? topSlot;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 6,
      top: 0,
      bottom: 0,
      child: Align(
        alignment: const Alignment(1, 0.32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (topSlot != null) ...[
              topSlot!,
              const SizedBox(height: 8),
            ],
            _RailBtn(
              label: 'Hediye',
              onTap: onGift,
              border: const Color(0xFFFF4D6D),
              fill: const Color(0x33FF4D6D),
              child: const Icon(
                Icons.diamond_rounded,
                size: 28,
                color: Color(0xFFFF7A59),
              ),
            ),
            const SizedBox(height: 8),
            _RailBtn(
              label: 'Müzik',
              onTap: onMusic,
              child: const Icon(
                Icons.music_note_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _RailBtn(
              label: 'PK',
              onTap: onPk,
              child: const _PkGlyph(),
            ),
            const SizedBox(height: 8),
            _RailBtn(
              label: 'İstek',
              onTap: onRequest,
              badge: requestPending,
              child: const Icon(
                Icons.groups_2_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _RailBtn(
              label: 'Daha Fazla',
              onTap: onMore,
              small: true,
              child: const Icon(
                Icons.format_list_bulleted_rounded,
                size: 26,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PkGlyph extends StatelessWidget {
  const _PkGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3D8B), Color(0xFFB832FF)],
        ),
      ),
      child: const Text(
        'PK',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: 16,
          height: 1,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RailBtn extends StatelessWidget {
  const _RailBtn({
    required this.label,
    required this.onTap,
    required this.child,
    this.border,
    this.fill,
    this.badge = false,
    this.small = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final Color? border;
  final Color? fill;
  final bool badge;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final b = border ?? VoiceRoomTokens.neonPurple.withValues(alpha: 0.7);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60,
        height: small ? 54 : 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: fill ?? const Color(0xCC1B0F36),
          border: Border.all(color: b, width: 1.3),
          boxShadow: [
            BoxShadow(color: b.withValues(alpha: 0.25), blurRadius: 10),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  child,
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: small ? 10.5 : 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (badge)
              const Positioned(
                top: 5,
                right: 5,
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Color(0xFFFF2D7A),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
