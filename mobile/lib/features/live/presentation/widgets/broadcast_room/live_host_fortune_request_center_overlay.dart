import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/live_fortune_request_entity.dart';
import '../../../domain/utils/live_fortune_display_label.dart';
import '../../providers/live_fortune_request_provider.dart';

/// Yayıncı — ekran ortasında fal isteği modalı + kuyruk (ONAYLA / REDDET).
class LiveHostFortuneRequestCenterOverlay extends ConsumerStatefulWidget {
  const LiveHostFortuneRequestCenterOverlay({
    super.key,
    required this.streamId,
  });

  final String streamId;

  @override
  ConsumerState<LiveHostFortuneRequestCenterOverlay> createState() =>
      _LiveHostFortuneRequestCenterOverlayState();
}

class _LiveHostFortuneRequestCenterOverlayState
    extends ConsumerState<LiveHostFortuneRequestCenterOverlay> {
  var _busy = false;
  String? _lastShownId;

  List<LiveFortuneRequestEntity> _pending(LiveFortuneRequestsState state) {
    return state.requests
        .where((r) => r.status == LiveFortuneRequestStatus.pending)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveFortuneRequestsProvider(widget.streamId));
    final pending = sortFortuneRequestQueue(_pending(state));
    if (pending.isEmpty) {
      _lastShownId = null;
      return const SizedBox.shrink();
    }

    final current = pending.first;
    if (_lastShownId != current.id) {
      _lastShownId = current.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) HapticFeedback.heavyImpact();
      });
    }

    final queueTotal = state.pendingCount;
    final queueIndex = 1;
    final fortune = liveFortuneTypePresentation(current.fortuneType);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 360),
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2A1548).withValues(alpha: 0.94),
                            const Color(0xFF12081F).withValues(alpha: 0.96),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFFB832FF).withValues(alpha: 0.55),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB832FF).withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (queueTotal > 1)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Text(
                                '🔮 $queueTotal Fal İsteği · $queueIndex/$queueTotal',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          const Text(
                            '🔮',
                            style: TextStyle(fontSize: 36),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Fal İsteği',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                const Color(0xFFB832FF).withValues(alpha: 0.35),
                            child: Text(
                              _initials(current.displayName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            current.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${fortune.emoji} ${fortune.title}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            current.question.trim().isNotEmpty
                                ? '"${current.question.trim()}"'
                                : 'Fal bakmamı istiyor.',
                            textAlign: TextAlign.center,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              fontStyle: current.question.trim().isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                          if (current.jetonCost > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${current.jetonCost} jeton',
                              style: TextStyle(
                                color: const Color(0xFFFFD54F)
                                    .withValues(alpha: 0.95),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: 'ONAYLA',
                                  icon: Icons.check_circle_rounded,
                                  color: const Color(0xFF2E7D32),
                                  busy: _busy,
                                  onTap: () => _respond(
                                    current.id,
                                    accept: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  label: 'REDDET',
                                  icon: Icons.cancel_rounded,
                                  color: const Color(0xFFC62828),
                                  busy: _busy,
                                  onTap: () => _respond(
                                    current.id,
                                    accept: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed:
                                _busy ? null : () => _hold(current.id),
                            child: Text(
                              'Beklet (sıraya al)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
                .animate(key: ValueKey(current.id))
                .fadeIn(duration: 220.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1, 1),
                  duration: 280.ms,
                  curve: Curves.easeOutBack,
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(String requestId, {required bool accept}) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    final notifier =
        ref.read(liveFortuneRequestsProvider(widget.streamId).notifier);
    try {
      if (accept) {
        await notifier.acceptRequest(requestId);
      } else {
        await notifier.rejectRequest(requestId);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _hold(String requestId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(liveFortuneRequestsProvider(widget.streamId).notifier)
          .holdRequest(requestId);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
