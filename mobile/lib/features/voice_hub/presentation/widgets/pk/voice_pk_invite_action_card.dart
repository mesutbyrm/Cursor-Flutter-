import 'package:flutter/material.dart';

/// Bekleyen PK daveti — skor yok; yalnızca kabul / reddet.
class VoicePkInviteActionCard extends StatelessWidget {
  const VoicePkInviteActionCard({
    super.key,
    required this.onAccept,
    required this.onReject,
    this.busy = false,
  });

  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PK DAVET',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB832FF),
                    ),
                    child: const Text('Kabul et'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
