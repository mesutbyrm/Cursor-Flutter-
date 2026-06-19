import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';

import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_fortune_types.dart';

/// Tam ekran gelen çağrı diyaloğu — `true` kabul, `false` red, `null` kapatma.
Future<bool?> showPsychicIncomingCallDialog(
  BuildContext context, {
  required String clientName,
  required String fortuneType,
  required int durationMinutes,
  required int totalJeton,
  String? clientAvatarUrl,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Canlı fal isteği',
    barrierColor: Colors.black.withValues(alpha: 0.85),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => _PsychicIncomingCallDialog(
      clientName: clientName,
      fortuneType: fortuneType,
      durationMinutes: durationMinutes,
      totalJeton: totalJeton,
      clientAvatarUrl: clientAvatarUrl,
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: child,
    ),
  );
}

class _PsychicIncomingCallDialog extends StatelessWidget {
  const _PsychicIncomingCallDialog({
    required this.clientName,
    required this.fortuneType,
    required this.durationMinutes,
    required this.totalJeton,
    this.clientAvatarUrl,
  });

  final String clientName;
  final String fortuneType;
  final int durationMinutes;
  final int totalJeton;
  final String? clientAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final timeLabel = TimeOfDay.now().format(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1450), Color(0xFF120A24), Color(0xFF0D0618)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppThemeColors.accentPink,
                        AppThemeColors.accentPurple,
                      ],
                    ),
                  ),
                  child: clientAvatarUrl != null && clientAvatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 56,
                          backgroundImage:
                              CachedNetworkImageProvider(clientAvatarUrl!),
                        )
                      : const UserAvatar(radius: 56),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Canlı Fal İsteği',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    text: clientName,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    children: [
                      TextSpan(
                        text: '\nsizinle canlı fal için bağlanmak istiyor',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '✨ ${psychicFortuneTypeLabel(fortuneType)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
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
                                fontSize: 17,
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
                      Container(width: 1, height: 40, color: Colors.white12),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$totalJeton jeton',
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
                _ActionBtn(
                  label: 'Kabul Et',
                  icon: Icons.call_rounded,
                  gradient: const [Color(0xFF00C853), Color(0xFF00E676)],
                  onTap: () => Navigator.pop(context, true),
                ),
                const SizedBox(height: 12),
                _ActionBtn(
                  label: 'Reddet',
                  icon: Icons.call_end_rounded,
                  gradient: const [Color(0xFFE53935), Color(0xFFFF5252)],
                  onTap: () => Navigator.pop(context, false),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Kapat',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
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
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
