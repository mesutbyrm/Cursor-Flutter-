import 'package:flutter/material.dart';

/// Odaya giriş sırasında premium skeleton — boş beyaz ekran yerine.
class VoiceRoomLoadingSkeleton extends StatelessWidget {
  const VoiceRoomLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _bar(width: 180, height: 18),
              const SizedBox(height: 10),
              _bar(width: 120, height: 12),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    alignment: WrapAlignment.center,
                    children: List.generate(8, (_) => _seat()),
                  ),
                ),
              ),
              _bar(height: 48),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _bar(height: 44)),
                  const SizedBox(width: 10),
                  _bar(width: 44, height: 44),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _seat() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
    );
  }
}
