import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/live_co_broadcast_constants.dart';
import '../../providers/co_broadcast_provider.dart';
import '../../providers/live_guest_request_blocklist_provider.dart';

/// Yayıncı — misafir katılma isteği (ortada ONAYLA / REDDET / Bu kişiye kapat).
class LiveHostGuestRequestCenterOverlay extends ConsumerStatefulWidget {
  const LiveHostGuestRequestCenterOverlay({
    super.key,
    required this.streamId,
    required this.currentGuestCount,
    required this.onApproved,
    required this.onRejected,
    required this.onBlocked,
  });

  final String streamId;
  final int currentGuestCount;
  final Future<void> Function(Map<String, dynamic> request) onApproved;
  final Future<void> Function(Map<String, dynamic> request) onRejected;
  final Future<void> Function(Map<String, dynamic> request) onBlocked;

  @override
  ConsumerState<LiveHostGuestRequestCenterOverlay> createState() =>
      _LiveHostGuestRequestCenterOverlayState();
}

class _LiveHostGuestRequestCenterOverlayState
    extends ConsumerState<LiveHostGuestRequestCenterOverlay> {
  var _busy = false;
  String? _lastShownKey;

  List<Map<String, dynamic>> _pending(CoBroadcastState state) {
    final blocklist = ref.read(liveGuestRequestBlocklistProvider(widget.streamId));
    return state.joinRequests.where((r) {
      final status = (r['status']?.toString() ?? 'pending').toLowerCase();
      if (status != 'pending') return false;
      final userId = (r['userId'] ?? r['id'] ?? '').toString();
      return userId.isEmpty || !blocklist.contains(userId);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coBroadcastProvider);
    final pending = _pending(state);
    if (pending.isEmpty) {
      _lastShownKey = null;
      return const SizedBox.shrink();
    }

    final current = pending.first;
    final requestKey = (current['id'] ?? current['userId'] ?? '').toString();
    if (_lastShownKey != requestKey) {
      _lastShownKey = requestKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) HapticFeedback.heavyImpact();
      });
    }

    final name = current['userName']?.toString() ??
        current['displayName']?.toString() ??
        'İzleyici';
    final queueTotal = pending.length;
    final slotsLeft = (kMaxLiveCoGuests - widget.currentGuestCount).clamp(0, 8);

    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(color: Colors.black.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A2A48).withValues(alpha: 0.94),
                        const Color(0xFF0A1020).withValues(alpha: 0.96),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF4FC3F7).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (queueTotal > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '👥 $queueTotal misafir isteği · 1/$queueTotal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.white, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'Misafir İsteği',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        slotsLeft > 0
                            ? 'Yayına misafir olarak katılmak istiyor.\nBoş koltuk: $slotsLeft / $kMaxLiveCoGuests'
                            : 'Misafir kotası dolu ($kMaxLiveCoGuests/8).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _Btn(
                              label: 'REDDET',
                              color: const Color(0xFFC62828),
                              busy: _busy,
                              onTap: slotsLeft > 0
                                  ? () => _act(current, _GuestAction.reject)
                                  : () => _act(current, _GuestAction.reject),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Btn(
                              label: 'ONAYLA',
                              color: const Color(0xFF2E7D32),
                              busy: _busy,
                              onTap: slotsLeft > 0
                                  ? () => _act(current, _GuestAction.approve)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed:
                            _busy ? null : () => _act(current, _GuestAction.block),
                        child: Text(
                          'Bu kişiye kapat',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate(key: ValueKey(requestKey)).fadeIn(duration: 200.ms),
        ],
      ),
    );
  }

  Future<void> _act(Map<String, dynamic> request, _GuestAction action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      switch (action) {
        case _GuestAction.approve:
          await widget.onApproved(request);
        case _GuestAction.reject:
          await widget.onRejected(request);
        case _GuestAction.block:
          await widget.onBlocked(request);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

enum _GuestAction { approve, reject, block }

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.color,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: (onTap == null ? Colors.grey : color).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
