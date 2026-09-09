import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// @mention bildirimi — hafif pulse, rahatsız etmeyen.
class VoiceRoomMentionNoticeBanner extends StatefulWidget {
  const VoiceRoomMentionNoticeBanner({
    super.key,
    required this.fromName,
    required this.preview,
    this.dismissKey,
    this.onDismiss,
    this.onTap,
  });

  final String fromName;
  final String preview;
  final Object? dismissKey;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  static const autoDismissDuration = Duration(seconds: 8);

  @override
  State<VoiceRoomMentionNoticeBanner> createState() =>
      _VoiceRoomMentionNoticeBannerState();
}

class _VoiceRoomMentionNoticeBannerState extends State<VoiceRoomMentionNoticeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _autoDismiss;
  Timer? _countdownTick;
  late DateTime _endsAt;
  Object? _trackedDismissKey;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _armAutoDismiss();
  }

  @override
  void didUpdateWidget(covariant VoiceRoomMentionNoticeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dismissKey != oldWidget.dismissKey) {
      _armAutoDismiss();
    }
  }

  void _armAutoDismiss() {
    final key = widget.dismissKey;
    if (key == _trackedDismissKey) return;
    _trackedDismissKey = key;
    _autoDismiss?.cancel();
    _countdownTick?.cancel();
    _endsAt = DateTime.now().add(VoiceRoomMentionNoticeBanner.autoDismissDuration);
    HapticFeedback.mediumImpact();
    if (widget.onDismiss == null) return;
    _autoDismiss = Timer(VoiceRoomMentionNoticeBanner.autoDismissDuration, () {
      if (!mounted) return;
      widget.onDismiss?.call();
    });
    _countdownTick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      if (DateTime.now().isAfter(_endsAt)) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _countdownTick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => _buildCard(_pulse.value),
    );
  }

  Widget _buildCard(double pulse) {
    final glow = 0.35 + pulse * 0.25;
    final remaining = _endsAt.difference(DateTime.now());
    final secs = remaining.inSeconds.clamp(0, 999);
    final progress = remaining.inMilliseconds <= 0
        ? 0.0
        : (remaining.inMilliseconds /
                VoiceRoomMentionNoticeBanner.autoDismissDuration.inMilliseconds)
            .clamp(0.0, 1.0);
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
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
              pulse,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                if (widget.onDismiss != null)
                  Text(
                    '${secs}s',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                IconButton(
                  onPressed: widget.onDismiss,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: Colors.white54,
                ),
              ],
            ),
            if (widget.onDismiss != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    Color.lerp(
                      const Color(0xFFB832FF),
                      const Color(0xFFFFD54F),
                      pulse,
                    )!,
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );

    if (widget.onDismiss == null) return card;

    return Dismissible(
      key: ValueKey(widget.dismissKey ?? widget.fromName),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => widget.onDismiss?.call(),
      child: card,
    );
  }
}
