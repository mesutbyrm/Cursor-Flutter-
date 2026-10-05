import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Sol kenar açılır panel — Müzik · PK · İstek · Daha Fazla. Kapalıyken yalnız
/// küçük bir tutamaç görünür; dokununca panel sola doğru açılır.
/// Yarışma kutuları (topSlot) sağ kenarda ayrı durur.
class VoiceMockSideRail extends StatefulWidget {
  const VoiceMockSideRail({
    super.key,
    required this.onMusic,
    required this.onPk,
    required this.onRequest,
    required this.onMore,
    this.requestPending = false,
    this.topSlot,
  });

  final VoidCallback onMusic;
  final VoidCallback onPk;
  final VoidCallback onRequest;
  final VoidCallback onMore;
  final bool requestPending;

  /// Yarışma kutuları (sağ kenar).
  final Widget? topSlot;

  @override
  State<VoiceMockSideRail> createState() => _VoiceMockSideRailState();
}

class _VoiceMockSideRailState extends State<VoiceMockSideRail> {
  var _open = false;

  void _run(VoidCallback action) {
    setState(() => _open = false);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          if (widget.topSlot != null)
            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: const Alignment(1, 0.32),
                child: widget.topSlot!,
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: const Alignment(-1, 0.32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.centerLeft,
                    child: _open
                        ? Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xE6100824),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: VoiceRoomTokens.neonPurple
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _RailBtn(
                                  label: 'Müzik',
                                  onTap: () => _run(widget.onMusic),
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _RailBtn(
                                  label: 'PK',
                                  onTap: () => _run(widget.onPk),
                                  child: const _PkGlyph(),
                                ),
                                const SizedBox(height: 8),
                                _RailBtn(
                                  label: 'İstek',
                                  onTap: () => _run(widget.onRequest),
                                  badge: widget.requestPending,
                                  child: const Icon(
                                    Icons.groups_2_rounded,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _RailBtn(
                                  label: 'Daha Fazla',
                                  onTap: () => _run(widget.onMore),
                                  small: true,
                                  child: const Icon(
                                    Icons.format_list_bulleted_rounded,
                                    size: 26,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  _RailHandle(
                    open: _open,
                    badge: widget.requestPending && !_open,
                    onTap: () => setState(() => _open = !_open),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailHandle extends StatelessWidget {
  const _RailHandle({
    required this.open,
    required this.badge,
    required this.onTap,
  });

  final bool open;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: open ? 'Menüyü kapat' : 'Menüyü aç',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 26,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xCC1B0F36),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(14),
            ),
            border: Border.all(
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                open
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: Colors.white,
                size: 24,
              ),
              if (badge)
                const Positioned(
                  top: 4,
                  right: 3,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: Color(0xFFFF2D7A),
                  ),
                ),
            ],
          ),
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
