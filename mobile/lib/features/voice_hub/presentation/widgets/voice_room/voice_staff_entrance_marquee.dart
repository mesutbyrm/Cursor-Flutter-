import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../domain/voice_official_join.dart';

/// Yetkili girişi — sağdan sola kayan şerit (canlifal.com).
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
  AnimationController? _scroll;
  double _textWidth = 0;
  double _viewWidth = 0;

  @override
  void initState() {
    super.initState();
    _scroll = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant VoiceStaffEntranceMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _textWidth = 0;
      _restartScroll();
    }
  }

  void _restartScroll() {
    final ctrl = _scroll;
    if (ctrl == null || _textWidth <= 0 || _viewWidth <= 0) return;
    final distance = _viewWidth + _textWidth + 48;
    final seconds = (distance / 52).clamp(6.0, 14.0);
    ctrl
      ..duration = Duration(milliseconds: (seconds * 1000).round())
      ..reset()
      ..repeat();
  }

  @override
  void dispose() {
    _scroll?.dispose();
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
    if (line.isEmpty) return const SizedBox.shrink();

    final textStyle = const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 11.5,
      color: Colors.white,
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
            border: Border.all(
              color: AppThemeColors.coinGold.withValues(alpha: 0.35),
            ),
          ),
          child: SizedBox(
            height: 32,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewWidth = constraints.maxWidth;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final painter = TextPainter(
                    text: TextSpan(text: line, style: textStyle),
                    maxLines: 1,
                    textDirection: TextDirection.ltr,
                  )..layout();
                  final w = painter.width;
                  if (w > 0 && (w - _textWidth).abs() > 1) {
                    _textWidth = w;
                    _restartScroll();
                  }
                });

                final ctrl = _scroll;
                if (ctrl == null) return const SizedBox.shrink();

                return AnimatedBuilder(
                  animation: ctrl,
                  builder: (context, _) {
                    final distance = _viewWidth + _textWidth + 48;
                    final offset = _viewWidth - (ctrl.value * distance);
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          left: offset,
                          top: 0,
                          bottom: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.workspace_premium_rounded,
                                  color: AppThemeColors.coinGold,
                                  size: 16,
                                ),
                              ),
                              Text(line, style: textStyle),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
