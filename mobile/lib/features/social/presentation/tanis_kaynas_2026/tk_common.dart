import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import 'tk_palette.dart';

/// Cam kart. Performans için `BackdropFilter` yerine yarı saydam dolgu +
/// ince kenarlık kullanılır (kaydırma sırasında bulanıklık GPU'yu zorluyor).
class TkGlassCard extends StatelessWidget {
  const TkGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

/// Basınca hafifçe küçülen + titreşim veren dokunma yüzeyi.
class TkPressable extends StatefulWidget {
  const TkPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.haptic = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<TkPressable> createState() => _TkPressableState();
}

class _TkPressableState extends State<TkPressable> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                if (widget.haptic) HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.5,
            duration: const Duration(milliseconds: 150),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class TkSectionHeader extends StatelessWidget {
  const TkSectionHeader({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailingText,
    this.onTap,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    final row = Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textFaint, fontSize: 12.5),
                ),
            ],
          ),
        ),
        if (trailingText != null)
          Flexible(
            child: Text(
              trailingText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(color: p.textMuted, fontSize: 12.5),
            ),
          ),
        if (onTap != null)
          Icon(Icons.chevron_right_rounded, color: p.textMuted, size: 22),
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: row,
    );
  }
}

/// Gradyan seçili / cam seçilmemiş çip.
class TkChip extends StatelessWidget {
  const TkChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return TkPressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 16,
          vertical: dense ? 8 : 10,
        ),
        decoration: BoxDecoration(
          gradient: selected ? TkPalette.primaryGradient : null,
          color: selected ? null : p.glass,
          borderRadius: BorderRadius.circular(dense ? 14 : 18),
          border: Border.all(
            color: selected ? Colors.transparent : p.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: TkPalette.pink.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: dense ? 16 : 18,
                color: selected ? Colors.white : (iconColor ?? p.textMuted),
              ),
              SizedBox(width: dense ? 5 : 7),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : p.text,
                fontSize: dense ? 12.5 : 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Basit iskelet kutusu (tek bir Shimmer sarmalayıcıyla kullanılır).
class TkSkeletonBox extends StatelessWidget {
  const TkSkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 12,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

class TkShimmer extends StatelessWidget {
  const TkShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return Shimmer.fromColors(
      baseColor: p.isDark ? const Color(0x22FFFFFF) : const Color(0x14000000),
      highlightColor:
          p.isDark ? const Color(0x44FFFFFF) : const Color(0x26000000),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

class TkEmptyState extends StatelessWidget {
  const TkEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.person_search_rounded,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return TkGlassCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: TkPalette.primaryGradient,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textMuted, fontSize: 13.5, height: 1.35),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TkGradientButton(label: actionLabel!, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

class TkErrorState extends StatelessWidget {
  const TkErrorState({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return TkEmptyState(
      icon: Icons.wifi_tethering_error_rounded,
      title: 'Bir şeyler ters gitti.',
      message: message ?? 'Bağlantını kontrol edip tekrar dene.',
      actionLabel: 'Tekrar Dene',
      onAction: onRetry,
    );
  }
}

class TkGradientButton extends StatelessWidget {
  const TkGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient = TkPalette.primaryGradient,
    this.icon,
    this.height = 44,
  });

  final String label;
  final VoidCallback? onTap;
  final Gradient gradient;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TkPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
