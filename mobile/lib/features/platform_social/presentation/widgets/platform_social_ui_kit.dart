import 'package:flutter/material.dart';

/// Profesyonel sosyal platform — ortak görsel dil (Tanış, Ajans, CFC Arena).
abstract final class PlatformSocialPalette {
  static const bgTop = Color(0xFF0B0F1E);
  static const bgBottom = Color(0xFF15102B);
  static const card = Color(0xFF1A1F35);
  static const cardBorder = Color(0x33FFFFFF);
  static const accent = Color(0xFFB832FF);
  static const accentSecondary = Color(0xFF448AFF);
  static const gold = Color(0xFFFFD54F);
  static const success = Color(0xFF4ADE80);
  static const danger = Color(0xFFFF6B6B);
  static const textMuted = Color(0x99FFFFFF);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgTop, bgBottom],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1B5E), Color(0xFF0F2847)],
  );
}

enum PlatformSocialPillTone { neutral, accent, success, gold, danger }

class PlatformSocialBackground extends StatelessWidget {
  const PlatformSocialBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: PlatformSocialPalette.backgroundGradient),
      child: child,
    );
  }
}

class PlatformSocialScaffold extends StatelessWidget {
  const PlatformSocialScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.body,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlatformSocialPalette.bgTop,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: PlatformSocialPalette.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: PlatformSocialBackground(
        child: SafeArea(child: body),
      ),
    );
  }
}

class PlatformSocialSectionTitle extends StatelessWidget {
  const PlatformSocialSectionTitle(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: PlatformSocialPalette.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class PlatformSocialGlassCard extends StatelessWidget {
  const PlatformSocialGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? PlatformSocialPalette.card.withValues(alpha: 0.92)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PlatformSocialPalette.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PlatformSocialStatusPill extends StatelessWidget {
  const PlatformSocialStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = PlatformSocialPillTone.neutral,
  });

  final String label;
  final IconData? icon;
  final PlatformSocialPillTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PlatformSocialPillTone.success => (
          PlatformSocialPalette.success.withValues(alpha: 0.2),
          PlatformSocialPalette.success,
        ),
      PlatformSocialPillTone.accent => (
          PlatformSocialPalette.accent.withValues(alpha: 0.22),
          PlatformSocialPalette.accent,
        ),
      PlatformSocialPillTone.gold => (
          PlatformSocialPalette.gold.withValues(alpha: 0.22),
          PlatformSocialPalette.gold,
        ),
      PlatformSocialPillTone.danger => (
          PlatformSocialPalette.danger.withValues(alpha: 0.2),
          PlatformSocialPalette.danger,
        ),
      PlatformSocialPillTone.neutral => (
          Colors.white.withValues(alpha: 0.08),
          Colors.white70,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PlatformSocialEmptyState extends StatelessWidget {
  const PlatformSocialEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Icon(icon, size: 48, color: PlatformSocialPalette.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PlatformSocialPalette.textMuted,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class PlatformSocialPrimaryButton extends StatelessWidget {
  const PlatformSocialPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: PlatformSocialPalette.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon ?? Icons.arrow_forward_rounded, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class PlatformSocialRankTile extends StatelessWidget {
  const PlatformSocialRankTile({
    super.key,
    required this.rank,
    required this.title,
    required this.subtitle,
    this.score,
    this.highlight = false,
  });

  final int rank;
  final String title;
  final String subtitle;
  final String? score;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank.',
    };
    return PlatformSocialGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      gradient: highlight
          ? LinearGradient(
              colors: [
                PlatformSocialPalette.gold.withValues(alpha: 0.15),
                PlatformSocialPalette.accent.withValues(alpha: 0.12),
              ],
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              medal,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: rank <= 3 ? 20 : 14,
                color: highlight ? PlatformSocialPalette.gold : Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: PlatformSocialPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (score != null)
            Text(
              score!,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: PlatformSocialPalette.accentSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class PlatformSocialInteractionTile extends StatelessWidget {
  const PlatformSocialInteractionTile({
    super.key,
    required this.actionLabel,
    required this.targetLabel,
    required this.icon,
    this.onTap,
  });

  final String actionLabel;
  final String targetLabel;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PlatformSocialGlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: PlatformSocialPalette.heroGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    targetLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PlatformSocialPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

IconData platformSocialActionIcon(String type) {
  switch (type) {
    case 'like':
      return Icons.favorite_rounded;
    case 'favorite':
      return Icons.star_rounded;
    case 'skip':
      return Icons.close_rounded;
    case 'friend_request':
      return Icons.person_add_rounded;
    case 'favorite':
      return Icons.star_rounded;
    default:
      return Icons.bolt_rounded;
  }
}

/// İstatistik kutusu (admin özet, ajans panel).
class PlatformSocialStatTile extends StatelessWidget {
  const PlatformSocialStatTile({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PlatformSocialGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: PlatformSocialPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiket + değer satırı (admin bilgi listesi).
class PlatformSocialInfoRow extends StatelessWidget {
  const PlatformSocialInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: PlatformSocialPalette.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Liste satırı — üye, kazanç, görev (ajans).
class PlatformSocialListRow extends StatelessWidget {
  const PlatformSocialListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PlatformSocialGlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: PlatformSocialPalette.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Keşif / swipe — yuvarlak aksiyon düğmesi.
class PlatformSocialCircleAction extends StatelessWidget {
  const PlatformSocialCircleAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tone = PlatformSocialPillTone.neutral,
  });

  final IconData icon;
  final VoidCallback onTap;
  final PlatformSocialPillTone tone;

  @override
  Widget build(BuildContext context) {
    final fg = switch (tone) {
      PlatformSocialPillTone.danger => PlatformSocialPalette.danger,
      PlatformSocialPillTone.accent => PlatformSocialPalette.accent,
      PlatformSocialPillTone.success => PlatformSocialPalette.success,
      _ => Colors.white70,
    };
    final bg = fg.withValues(alpha: 0.22);
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: fg, size: 28),
        ),
      ),
    );
  }
}
