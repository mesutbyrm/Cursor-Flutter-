import 'package:flutter/material.dart';

import '../../../domain/pk/pk_battle_remote_models.dart';

/// Orta ekran PK daveti — premium, okunabilir.
Future<bool?> showVoicePkInviteCenterModal({
  required BuildContext context,
  required String challengerLabel,
  required PkBattleRemote battle,
}) {
  final minutes = (battle.durationSeconds / 60).round();
  final durationHint = minutes > 0 ? '$minutes dk' : null;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: const Color(0xFF1A0F2E),
            elevation: 18,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 10),
                  const Text(
                    'PK İSTEĞİ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '@$challengerLabel seninle PK yapmak istiyor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  if (durationHint != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Süre: $durationHint',
                      style: TextStyle(
                        color: const Color(0xFFB832FF).withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'REDDET',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFB832FF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'KABUL ET',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
