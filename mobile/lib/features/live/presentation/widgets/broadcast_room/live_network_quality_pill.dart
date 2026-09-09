import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// TRTC ağ kalitesi — 🟢 İyi / 🟡 Orta / 🔴 Zayıf.
class LiveNetworkQualityPill extends StatelessWidget {
  const LiveNetworkQualityPill({
    super.key,
    required this.qualityListenable,
  });

  final ValueListenable<int?> qualityListenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: qualityListenable,
      builder: (context, q, _) {
        final (label, color, emoji) = _map(q);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  (String, Color, String) _map(int? quality) {
    if (quality == null) {
      return ('Bağlanıyor', Colors.white70, '⚪');
    }
    return switch (quality) {
      0 || 1 => ('İyi', const Color(0xFF66BB6A), '🟢'),
      2 || 3 => ('Orta', const Color(0xFFFFCA28), '🟡'),
      _ => ('Zayıf', const Color(0xFFEF5350), '🔴'),
    };
  }
}
