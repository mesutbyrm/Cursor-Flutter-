import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../domain/entities/live_fortune_teller_entity.dart';

/// Danışan onayı — falcıya bağlanmadan önce süre/jeton özeti.
Future<bool?> showLiveFortuneClientBookingSheet(
  BuildContext context, {
  required LiveFortuneTellerEntity teller,
  required int durationMinutes,
  required int totalJeton,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LiveFortuneClientBookingSheet(
      teller: teller,
      durationMinutes: durationMinutes,
      totalJeton: totalJeton,
    ),
  );
}

class _LiveFortuneClientBookingSheet extends StatelessWidget {
  const _LiveFortuneClientBookingSheet({
    required this.teller,
    required this.durationMinutes,
    required this.totalJeton,
  });

  final LiveFortuneTellerEntity teller;
  final int durationMinutes;
  final int totalJeton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E2A48).withValues(alpha: 0.96),
                  const Color(0xFF120A24).withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.video_chat_rounded,
                  color: AppThemeColors.accentCyan,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Canlı Fal Bağlantısı',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: teller.name,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      TextSpan(
                        text: ' ile $durationMinutes dakikalık seans',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '✨ ${teller.displayCategory}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$durationMinutes dk',
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Süre',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 36, color: Colors.white12),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$totalJeton jeton',
                              style: const TextStyle(
                                color: AppThemeColors.accentCyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ücret',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'İsteğiniz falcıya iletilecek. Kabul ettiğinde seans başlar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 18),
                _ActionBtn(
                  label: 'Falcıya Bağlan',
                  icon: Icons.send_rounded,
                  gradient: const [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                  onTap: () => Navigator.pop(context, true),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Vazgeç'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
