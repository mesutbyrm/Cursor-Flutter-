import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

import '../social_linked_caption_text.dart';

/// Gönderi metni: ekrana sığdığı kadar ([maxLines] satır) gösterilir, sığmayan
/// metin "…" ile kesilir ve "Daha fazla" ile yerinde tamamı açılır.
class SocialExpandableCaption extends StatefulWidget {
  const SocialExpandableCaption({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 4,
  });

  final String text;
  final TextStyle style;
  final int maxLines;

  /// Metin [maxLines] satıra sığmıyor mu? (Ölçüm — test edilebilir.)
  static bool exceeds({
    required String text,
    required TextStyle style,
    required int maxLines,
    required double maxWidth,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);
    final result = painter.didExceedMaxLines;
    painter.dispose();
    return result;
  }

  @override
  State<SocialExpandableCaption> createState() =>
      _SocialExpandableCaptionState();
}

class _SocialExpandableCaptionState extends State<SocialExpandableCaption> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final overflow =
            c.maxWidth.isFinite &&
            SocialExpandableCaption.exceeds(
              text: widget.text,
              style: widget.style,
              maxLines: widget.maxLines,
              maxWidth: c.maxWidth,
              textScaler: scaler,
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SocialLinkedCaptionText(
              text: widget.text,
              style: widget.style,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            if (overflow)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 2),
                  child: Text(
                    _expanded ? 'Daha az' : 'Daha fazla',
                    style: TextStyle(
                      color: _expanded
                          ? context.colors.onSurfaceMuted
                          : (context.isDarkTheme
                                ? AppThemeColors.accentCyan
                                : context.colors.secondary),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
