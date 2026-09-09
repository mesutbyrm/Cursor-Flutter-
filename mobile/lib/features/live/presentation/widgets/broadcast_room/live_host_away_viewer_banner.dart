import 'package:flutter/material.dart';

/// İzleyici — yayıncı bağlantısı koptuğunda kalıcı bilgi bandı.
class LiveHostAwayViewerBanner extends StatelessWidget {
  const LiveHostAwayViewerBanner({
    super.key,
    this.graceMinutes = 5,
  });

  final int graceMinutes;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: top + 96,
      left: 16,
      right: 16,
      child: Material(
        color: const Color(0xFF2A1545).withValues(alpha: 0.94),
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Color(0xFFFFB74D), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Yayıncının bağlantısı koptu. Yayın ~$graceMinutes dk daha açık — geri döndüğünde devam edecek.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
