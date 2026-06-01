import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';


/// Oda kuralları — girişte görünür; yazı yazılınca yukarı kayıp solar.
class VoiceRoomRulesTicker extends StatefulWidget {
  const VoiceRoomRulesTicker({
    super.key,
    required this.rules,
    required this.typing,
  });

  final String rules;
  final bool typing;

  @override
  State<VoiceRoomRulesTicker> createState() => _VoiceRoomRulesTickerState();
}

class _VoiceRoomRulesTickerState extends State<VoiceRoomRulesTicker> {
  var _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scheduleAutoHide();
  }

  @override
  void didUpdateWidget(covariant VoiceRoomRulesTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.typing && !oldWidget.typing) {
      setState(() => _visible = false);
    }
    if (widget.rules != oldWidget.rules) {
      setState(() => _visible = true);
      _scheduleAutoHide();
    }
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    if (!widget.typing) {
      _hideTimer = Timer(const Duration(seconds: 12), () {
        if (mounted && !widget.typing) setState(() => _visible = false);
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.rules.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    return AnimatedSlide(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      offset: _visible && !widget.typing ? Offset.zero : const Offset(0, -0.35),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 380),
        opacity: _visible && !widget.typing ? 1 : 0,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                AppThemeColors.accentPurple.withValues(alpha: 0.35),
                context.colors.surfaceContainer.withValues(alpha: 0.5),
              ],
            ),
            border: Border.all(
              color: AppThemeColors.accentCyan.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Oda kuralları',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: AppThemeColors.accentCyan,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: context.colors.onSurfaceVariant.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
