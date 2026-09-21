import 'package:flutter/material.dart';

/// Canlı seans timer'ı — Göz önünde, büyük, yanıp sönen uyarı
class PsychicSessionTimerDisplay extends StatelessWidget {
  const PsychicSessionTimerDisplay({
    required this.timeRemaining,
    required this.totalDuration,
    this.isLowTime = false,
    this.onExtendPressed,
  });

  final Duration timeRemaining;
  final Duration totalDuration;
  final bool isLowTime;
  final VoidCallback? onExtendPressed;

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progressValue {
    if (totalDuration.inSeconds == 0) return 0;
    return timeRemaining.inSeconds / totalDuration.inSeconds;
  }

  Color get _timerColor {
    if (isLowTime) return Colors.red;
    if (_progressValue < 0.25) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(timeRemaining);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _timerColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _timerColor.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Timer Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _timerColor.withValues(alpha: 0.1),
              border: Border.all(
                color: _timerColor.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                    fontSize: 48,
                    color: _timerColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kalan Süre',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progressValue,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(_timerColor),
            ),
          ),
          const SizedBox(height: 12),

          // Status Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLowTime ? '⚠️ Süre azalıyor!' : '✓ Seans devam ediyor',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLowTime ? Colors.orange : Colors.green,
                ),
              ),
              Text(
                '${(_progressValue * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          // Extend Button (if low time)
          if (isLowTime && onExtendPressed != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onExtendPressed,
              icon: const Icon(Icons.alarm, size: 16),
              label: const Text('Uzat'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(36),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
