import 'package:flutter/material.dart';

import '../../theme/home_approved_design.dart';
import '../../theme/home_premium_design.dart';
import '../approved/home_section_title.dart';

/// Bölüm başlığı + içerik / yükleme / hata / boş durum kabuğu.
class HomeSectionShell extends StatelessWidget {
  const HomeSectionShell({
    super.key,
    required this.emoji,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.loading,
    this.errorMessage,
    this.onRetry,
    this.emptyIcon,
    this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.child,
    this.contentHeight,
  });

  final String emoji;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final Widget? loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final IconData? emptyIcon;
  final String? emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final Widget? child;
  final double? contentHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: HomeSectionTitle(
                emoji: emoji,
                title: title,
                actionLabel: actionLabel,
                onAction: onAction,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (loading != null)
          loading!
        else if (errorMessage != null)
          _InlineState(
            height: contentHeight,
            icon: Icons.refresh_rounded,
            message: errorMessage!,
            actionLabel: 'Tekrar Dene',
            onAction: onRetry,
          )
        else if (emptyMessage != null && child == null)
          _InlineState(
            height: contentHeight,
            icon: emptyIcon ?? Icons.inbox_outlined,
            message: emptyMessage!,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
          )
        else if (child != null)
          child!,
      ],
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({
    required this.message,
    this.height,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final double? height;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      margin: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        0,
        HomeApprovedDesign.hPad,
        12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: HomePremiumDesign.glassCard(
        tint: HomePremiumDesign.surface,
        radius: HomePremiumDesign.chipRadius,
      ),
      child: Row(
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 20,
              color: HomeApprovedDesign.textMuted.withValues(alpha: 0.9),
            ),
          if (icon != null) const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: HomePremiumDesign.secondarySize,
                color: HomeApprovedDesign.textSecondary,
                height: 1.25,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: HomePremiumDesign.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: HomePremiumDesign.actionLabelStyle.copyWith(fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: Center(child: body));
    }
    return body;
  }
}
