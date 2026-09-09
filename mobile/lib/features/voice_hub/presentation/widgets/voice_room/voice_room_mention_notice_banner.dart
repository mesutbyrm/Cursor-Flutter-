import 'package:flutter/material.dart';

/// @mention bildirimi — hafif pulse, rahatsız etmeyen.
class VoiceRoomMentionNoticeBanner extends StatefulWidget {
  const VoiceRoomMentionNoticeBanner({
    super.key,
    required this.fromName,
    required this.preview,
    this.onDismiss,
    this.onTap,
  });

  final String fromName;
  final String preview;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  @override
  State<VoiceRoomMentionNoticeBanner> createState() =>
      _VoiceRoomMentionNoticeBannerState();
}

class _VoiceRoomMentionNoticeBannerState extends State<VoiceRoomMentionNoticeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = 0.35 + _pulse.value * 0.25;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1035).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Color.lerp(
              const Color(0xFFB832FF),
              const Color(0xFFFFD54F),
              _pulse.value,
            )!
                .withValues(alpha: glow),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB832FF).withValues(alpha: glow * 0.35),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Senden bahsetti',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '@${widget.fromName}: ${widget.preview}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: Colors.white54,
            ),
          ],
        ),
        ),
      ),
    );
  }
}
