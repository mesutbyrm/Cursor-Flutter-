import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Oda ayarları panelinin ortak kartı: cam efekti, ikon, başlık, kısa açıklama
/// ve sağda chevron. Ana menü ile tüm alt menüler aynı kartı kullanır.
class VoiceMgmtCard extends StatelessWidget {
  const VoiceMgmtCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = VoiceRoomTokens.neonBlue,
    this.badge,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  /// Sağ üstte küçük sayaç/etiket (ör. "3").
  final String? badge;

  /// Yetki yok / kilitli: soluk görünür, dokununca yine [onTap] çalışır
  /// (çağıran taraf açıklayıcı mesaj gösterir).
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    final opacity = locked ? 0.55 : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Opacity(
        opacity: opacity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: dark ? 0.20 : 0.14),
                        (dark ? Colors.white : scheme.surface)
                            .withValues(alpha: dark ? 0.06 : 0.55),
                      ],
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: accent.withValues(alpha: 0.22),
                        ),
                        child: Icon(
                          locked ? Icons.lock_outline_rounded : icon,
                          color: accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: fg,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.25,
                                color: fg.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (badge != null && badge!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: fg.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alt menülerde grup başlığı.
class VoiceMgmtSectionTitle extends StatelessWidget {
  const VoiceMgmtSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
          letterSpacing: 0.3,
          color: VoiceRoomTokens.neonBlue.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}
