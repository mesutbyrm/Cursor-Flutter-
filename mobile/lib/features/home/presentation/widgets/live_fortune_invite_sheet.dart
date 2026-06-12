import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

/// Falcıya düşen canlı fal daveti — Kabul / Beklet / Reddet.
Future<bool?> showLiveFortuneTellerInviteSheet(
  BuildContext context, {
  required String clientName,
  required String category,
  required int durationMinutes,
  required int totalJeton,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Canlı fal daveti',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Colors.transparent,
          child: _LiveFortuneInviteSheet(
            clientName: clientName,
            category: category,
            durationMinutes: durationMinutes,
            totalJeton: totalJeton,
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, _, __, child) => child,
  );
}

class _LiveFortuneInviteSheet extends StatelessWidget {
  const _LiveFortuneInviteSheet({
    required this.clientName,
    required this.category,
    required this.durationMinutes,
    required this.totalJeton,
  });

  final String clientName;
  final String category;
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
      child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A1450),
                  Color(0xFF120A24),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppThemeColors.accentPink.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppThemeColors.accentPink,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Canlı Fal İsteği',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: clientName,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w800,
                    ),
                    children: const [
                      TextSpan(
                        text: ' sizinle canlı fal için bağlanmak istiyor',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '✨ $category',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              '$durationMinutes dakika',
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Seçilen Süre',
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
                              'Toplam Tutar',
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
                const SizedBox(height: 18),
                _ActionBtn(
                  label: 'Kabul Et',
                  icon: Icons.call_rounded,
                  gradient: const [Color(0xFF00C853), Color(0xFF00E676)],
                  onTap: () => Navigator.pop(context, true),
                ),
                const SizedBox(height: 8),
                _ActionBtn(
                  label: 'Beklet',
                  icon: Icons.schedule_rounded,
                  gradient: const [Color(0xFFFFB300), Color(0xFFFFD54F)],
                  foreground: Colors.black87,
                  onTap: () => Navigator.pop(context, null),
                ),
                const SizedBox(height: 8),
                _ActionBtn(
                  label: 'Reddet',
                  icon: Icons.call_end_rounded,
                  gradient: const [Color(0xFFE53935), Color(0xFFFF5252)],
                  onTap: () => Navigator.pop(context, false),
                ),
              ],
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
    this.foreground = Colors.white,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final Color foreground;

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
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
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
