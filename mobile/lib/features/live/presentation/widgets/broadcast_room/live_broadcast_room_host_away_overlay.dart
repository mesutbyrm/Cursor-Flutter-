import 'package:flutter/material.dart';

/// Yayıncı bağlantı koptu — tam ekran grace overlay.
class LiveBroadcastRoomHostAwayOverlay extends StatelessWidget {
  const LiveBroadcastRoomHostAwayOverlay({
    super.key,
    required this.onResume,
    required this.onEndBroadcast,
  });

  final VoidCallback onResume;
  final VoidCallback onEndBroadcast;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Bağlantı koptu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yayın 5 dakika daha açık. Geri döndüğünüzde devam edebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(
                  button: true,
                  label: 'Yayına devam et',
                  child: FilledButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Yayına devam et'),
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  button: true,
                  label: 'Yayını bitir',
                  child: TextButton(
                    onPressed: onEndBroadcast,
                    child: const Text('Yayını bitir'),
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
