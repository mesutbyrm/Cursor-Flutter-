import 'package:flutter/material.dart';

/// PK split ekranında bağlantı yenileme — video katmanı kapanmaz.
class LivePkReconnectBanner extends StatelessWidget {
  const LivePkReconnectBanner({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 96,
      left: 16,
      right: 16,
      child: Material(
        color: const Color(0xFF1A1035).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFB832FF),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bağlantı yeniden kuruluyor… PK devam ediyor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
