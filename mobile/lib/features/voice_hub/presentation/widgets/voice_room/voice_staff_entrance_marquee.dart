import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../../core/auth/voice_staff_rank.dart';
import '../../../domain/voice_official_join.dart';

/// Yetkili girişi — sesli bölüm altında sağdan sola şerit.
class VoiceStaffEntranceMarquee extends StatefulWidget {
  const VoiceStaffEntranceMarquee({
    super.key,
    required this.message,
  });

  final String? message;

  @override
  State<VoiceStaffEntranceMarquee> createState() =>
      _VoiceStaffEntranceMarqueeState();
}

class _VoiceStaffEntranceMarqueeState extends State<VoiceStaffEntranceMarquee> {
  Timer? _clearTimer;

  @override
  void didUpdateWidget(covariant VoiceStaffEntranceMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != null &&
        widget.message!.isNotEmpty &&
        widget.message != oldWidget.message) {
      _clearTimer?.cancel();
      _clearTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.message?.trim() ?? '';
    if (raw.isEmpty) return const SizedBox.shrink();

    final marqueeText = _marqueeLine(raw);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: ClipPath(
        clipper: _RibbonClipper(),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemeColors.coinGold.withValues(alpha: 0.45),
                AppThemeColors.accentPurple.withValues(alpha: 0.55),
                AppThemeColors.accentPink.withValues(alpha: 0.4),
              ],
            ),
            boxShadow: AppThemeColors.glowShadow(AppThemeColors.coinGold, blur: 12),
          ),
          child: _MarqueeText(text: marqueeText),
        ),
      ),
    );
  }

  String _marqueeLine(String raw) {
    if (VoiceOfficialJoin.isOfficialEntrance(raw) &&
        !raw.startsWith('[SYSTEM_VIP_JOIN:')) {
      final line = raw.contains('📣') ? raw : '📣 $raw';
      return line.endsWith('🎤') ? line : '$line 🎤';
    }
    final parsed = _parseStaffJoin(raw);
    final label = parsed.$1;
    final name = parsed.$2;
    final rank = parsed.$3;
    final sym = VoiceStaffRankParser.prefixSymbol(rank) ?? '★';
    return '$sym $label $name odaya katıldı! 🎤';
  }

  (String, String, VoiceStaffRank) _parseStaffJoin(String raw) {
    if (raw.startsWith('[SYSTEM_VIP_JOIN:')) {
      final inner = raw
          .replaceFirst('[SYSTEM_VIP_JOIN:', '')
          .replaceAll(']', '');
      final parts = inner.split(':');
      final tag = parts.isNotEmpty ? parts.first : 'STAFF';
      final name = parts.length > 1 ? parts.sublist(1).join(':') : 'Yetkili';
      final rank = tag == 'STAFF'
          ? VoiceStaffRankParser.fromUsername(name)
          : VoiceStaffRank.none;
      final label = VoiceStaffRankParser.displayPrefix(rank);
      return (label.isEmpty ? 'Yetkili' : label, name.replaceFirst(RegExp(r'^[~&@%]'), ''), rank);
    }
    return ('Yetkili', raw, VoiceStaffRank.admin);
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text});

  final String text;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _ctrl
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final textW = w + 280;
            final offset = _ctrl.value * textW;
            return ClipRect(
              child: Transform.translate(
                offset: Offset(w - offset, 0),
                child: child,
              ),
            );
          },
        );
      },
      child: Text(
        widget.text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const notch = 10.0;
    path.moveTo(notch, 0);
    path.lineTo(size.width - notch, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - notch, size.height);
    path.lineTo(notch, size.height);
    path.lineTo(0, size.height / 2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
