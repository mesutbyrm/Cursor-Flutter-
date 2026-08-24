import 'package:flutter/material.dart';

/// Bakım modu — `maintenance.enabled == true`.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = (message?.trim().isNotEmpty == true)
        ? message!.trim()
        : 'Uygulama şu anda bakımda. Lütfen daha sonra tekrar deneyin.';

    return Material(
      color: const Color(0xFF05050D),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 56,
                color: Color(0xFF9B4DFF),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bakımdayız',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
