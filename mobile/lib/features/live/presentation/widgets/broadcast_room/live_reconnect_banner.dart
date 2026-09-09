import 'package:flutter/material.dart';

/// Canlı yayın yeniden bağlanma — kalıcı üst banner.
class LiveReconnectBanner extends StatelessWidget {
  const LiveReconnectBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.topPadding = 52,
  });

  final String message;
  final VoidCallback? onRetry;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + topPadding,
      left: 16,
      right: 16,
      child: Material(
        color: const Color(0xFF1A1035).withValues(alpha: 0.94),
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFB832FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Tekrar dene',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
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
