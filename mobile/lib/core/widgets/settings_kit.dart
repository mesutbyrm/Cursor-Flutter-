import 'package:flutter/material.dart';

import '../design_system/cds_colors.dart';
import '../theme/app_theme_extensions.dart';

/// Ayarlar ekranları için ortak "kutucuk" bileşenleri.
///
/// Tüm ayar sayfaları (ana ayarlar, bildirim, ses, cihazlar…) aynı görsel dili
/// kullanır: bölüm başlığı + 2 sütunlu kutucuk ızgarası + tam genişlik panel.

/// Bölüm başlığı — küçük renkli ikon + kalın başlık.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: c.primary),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.2,
              color: c.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// İki sütunlu kutucuk ızgarası. Tek sayıda çocuk varsa son kutucuk yarım
/// genişlikte kalır (boşluk bırakılır, taşma olmaz).
class SettingsTileGrid extends StatelessWidget {
  const SettingsTileGrid({
    super.key,
    required this.children,
    this.spacing = 10,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: w, child: child),
          ],
        );
      },
    );
  }
}

/// Dokunulabilir ayar kutucuğu: renkli ikon rozeti + başlık + (opsiyonel) alt metin.
class SettingsTileCard extends StatelessWidget {
  const SettingsTileCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.subtitle,
    this.accent,
    this.destructive = false,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String? subtitle;

  /// Boşsa kutucuk yalnızca bilgi gösterir (dokunma efekti yok).
  final VoidCallback? onTap;
  final Color? accent;
  final bool destructive;

  /// Sağ üst köşede küçük rozet metni (ör. "Yeni").
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = destructive ? CdsColors.error : (accent ?? c.primary);
    return _TileShell(
      onTap: onTap,
      borderTint: destructive ? CdsColors.error : null,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconBadge(icon: icon, tint: tint),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  height: 1.2,
                  color: destructive ? CdsColors.error : c.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.25,
                    color: c.onSurfaceMuted,
                  ),
                ),
              ],
            ],
          ),
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Açma/kapama kutucuğu — kutucuğun tamamına dokunmak anahtarı değiştirir.
class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = accent ?? c.primary;
    return _TileShell(
      onTap: () => onChanged(!value),
      borderTint: value ? tint : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _IconBadge(icon: icon, tint: tint, active: value),
              const Spacer(),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              height: 1.2,
              color: c.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.25,
                color: c.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tam genişlik kart — kaydırıcı, seçici gibi büyük kontroller için.
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.accent,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Color? accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Material: içindeki ListTile/Radio/Switch dokunma efektleri görünsün diye
    // arka plan Container değil Material üzerinde çizilir.
    return Material(
      color: c.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    _IconBadge(
                      icon: icon!,
                      tint: accent ?? c.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: c.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Üstte büyük, ikonlu özet kartı (hesap başlığı vb.).
class SettingsHeroCard extends StatelessWidget {
  const SettingsHeroCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                c.primary.withValues(alpha: 0.28),
                c.secondary.withValues(alpha: 0.16),
              ],
            ),
            border: Border.all(color: c.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: c.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: c.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: c.onSurfaceMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileShell extends StatelessWidget {
  const _TileShell({required this.child, required this.onTap, this.borderTint});

  final Widget child;
  final VoidCallback? onTap;
  final Color? borderTint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(20);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        splashColor: c.primary.withValues(alpha: 0.12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: c.surfaceContainer,
            border: Border.all(
              color: borderTint?.withValues(alpha: 0.55) ?? c.glassBorder,
              width: borderTint != null ? 1.4 : 1,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 112),
            child: Padding(padding: const EdgeInsets.all(14), child: child),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.tint,
    this.active = true,
    this.size = 40,
  });

  final IconData icon;
  final Color tint;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: active ? 0.32 : 0.14),
            tint.withValues(alpha: active ? 0.14 : 0.06),
          ],
        ),
      ),
      child: Icon(icon, color: tint, size: size * 0.52),
    );
  }
}
