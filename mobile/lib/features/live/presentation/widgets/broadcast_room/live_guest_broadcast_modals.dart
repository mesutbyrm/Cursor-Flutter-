import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// İzleyici — yayıncı misafir daveti (TikTok/BIGO tarzı orta popup).
Future<bool?> showViewerGuestInviteModal({
  required BuildContext context,
  required String hostName,
}) {
  HapticFeedback.heavyImpact();
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Misafir daveti',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    pageBuilder: (ctx, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _GuestInviteCard(
          hostName: hostName,
          onAccept: () => Navigator.pop(ctx, true),
          onReject: () => Navigator.pop(ctx, false),
        ),
      ),
    ),
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        ),
        child: child,
      ),
    ),
  );
}

/// Yayıncı — yayını bitir onayı.
Future<bool?> showLiveEndConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1030),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Yayını bitir',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
      content: const Text(
        'Canlı yayını bitirmek istediğine emin misin?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Devam Et'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
          child: const Text('Yayını Bitir'),
        ),
      ],
    ),
  );
}

class _GuestInviteCard extends StatelessWidget {
  const _GuestInviteCard({
    required this.hostName,
    required this.onAccept,
    required this.onReject,
  });

  final String hostName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2A1548).withValues(alpha: 0.95),
                const Color(0xFF12081F).withValues(alpha: 0.97),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_alt_rounded, color: Colors.white, size: 42),
              const SizedBox(height: 10),
              const Text(
                'Misafir Daveti',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hostName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'sizi misafirliğe davet etti.\nKabul ederseniz kameranız ve sesiniz herkese görünür.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ModalBtn(
                      label: 'REDDET',
                      color: const Color(0xFFC62828),
                      onTap: onReject,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModalBtn(
                      label: 'KABUL ET',
                      color: const Color(0xFF2E7D32),
                      onTap: onAccept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1, 1),
          duration: 280.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _ModalBtn extends StatelessWidget {
  const _ModalBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
