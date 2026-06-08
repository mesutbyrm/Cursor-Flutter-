import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../domain/voice_official_join.dart';

/// Yetkili girişi — kayan şerit (5 sn gösterilir, provider tarafından kapatılır).
class VoiceStaffEntranceMarquee extends StatefulWidget {
  const VoiceStaffEntranceMarquee({
    super.key,
    required this.message,
    this.roomName,
  });

  final String? message;
  final String? roomName;

  @override
  State<VoiceStaffEntranceMarquee> createState() =>
      _VoiceStaffEntranceMarqueeState();
}

class _VoiceStaffEntranceMarqueeState extends State<VoiceStaffEntranceMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.message?.trim() ?? '';
    if (raw.isEmpty) return const SizedBox.shrink();

    final line = VoiceOfficialJoin.formatEntranceBanner(
      raw,
      roomName: widget.roomName,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemeColors.coinGold.withValues(alpha: 0.22),
                AppThemeColors.accentPurple.withValues(alpha: 0.35),
              ],
            ),
            border: Border.all(color: AppThemeColors.coinGold.withValues(alpha: 0.35)),
          ),
          child: SizedBox(
            height: 32,
            child: AnimatedBuilder(
              animation: _scroll,
              builder: (context, _) {
                return OverflowBox(
                  maxWidth: double.infinity,
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(-_scroll.value * 120, 0),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            color: AppThemeColors.coinGold,
                            size: 16,
                          ),
                        ),
                        Text(
                          line,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 48),
                        Text(
                          line,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
