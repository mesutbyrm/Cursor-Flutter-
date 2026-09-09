import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_room_providers.dart';
import '../../utils/voice_room_chat_flood_guard.dart';

/// Oda sohbeti flood uyarısı — geri sayım + otomatik temizleme.
class VoiceRoomChatFloodBanner extends ConsumerStatefulWidget {
  const VoiceRoomChatFloodBanner({
    super.key,
    required this.liveKey,
    required this.message,
  });

  final String liveKey;
  final String message;

  @override
  ConsumerState<VoiceRoomChatFloodBanner> createState() =>
      _VoiceRoomChatFloodBannerState();
}

class _VoiceRoomChatFloodBannerState extends ConsumerState<VoiceRoomChatFloodBanner> {
  Timer? _timer;
  late Duration _total;
  late DateTime _endsAt;

  @override
  void initState() {
    super.initState();
    _armCountdown();
  }

  @override
  void didUpdateWidget(covariant VoiceRoomChatFloodBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _armCountdown();
    }
  }

  void _armCountdown() {
    _timer?.cancel();
    final guard = VoiceRoomChatFloodGuard();
    _total = guard.cooldownForMessage(widget.message);
    _endsAt = DateTime.now().add(_total);
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      if (DateTime.now().isAfter(_endsAt)) {
        _timer?.cancel();
        ref.read(voiceRoomLiveProvider(widget.liveKey).notifier).clearError();
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _endsAt.difference(DateTime.now());
    final secs = remaining.inSeconds.clamp(0, 999);
    final progress = _total.inMilliseconds <= 0
        ? 0.0
        : (remaining.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
    final icon = widget.message == VoiceRoomChatFloodGuard.duplicateMessage
        ? Icons.copy_rounded
        : Icons.speed_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF8F00).withValues(alpha: 0.22),
                const Color(0xFFFF5252).withValues(alpha: 0.14),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: const Color(0xFFFFD54F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${secs}s',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD54F)),
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
