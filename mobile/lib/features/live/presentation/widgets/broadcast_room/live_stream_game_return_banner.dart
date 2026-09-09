import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Canlı yayından oyun lobisine geçildiğinde «yayına dön» çubuğu.
class LiveStreamGameReturnBanner extends StatelessWidget {
  const LiveStreamGameReturnBanner({
    super.key,
    required this.streamId,
    this.gameRoomId,
  });

  final String streamId;
  final String? gameRoomId;

  @override
  Widget build(BuildContext context) {
    if (streamId.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Material(
        color: const Color(0xFFB832FF).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/discover');
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.live_tv_rounded, color: Color(0xFFB832FF), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Canlı yayın devam ediyor',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        gameRoomId != null && gameRoomId!.isNotEmpty
                            ? 'Oyun odası açık — yayına geri dön'
                            : 'Yayına geri dön',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
