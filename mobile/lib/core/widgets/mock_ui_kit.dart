import 'package:flutter/material.dart';

import '../theme/app_theme_extensions.dart';
import '../../features/feed/presentation/widgets/discover/discover_background.dart';

/// Profil / Ayarlar / Yönetim ekranlarının ortak "mockup" görsel dili:
/// ortalanmış başlıklı üst çubuk, mor tonlu koyu kartlar, düz renkli ikon kareleri.

/// Koyu temada mor tonlu kart zemini; açık temada tema yüzeyi.
Color mockCardColor(BuildContext context) {
  final c = context.colors;
  return context.isDarkTheme ? const Color(0xFF1A1433) : c.surfaceContainer;
}

Color mockCardBorder(BuildContext context) {
  return context.isDarkTheme
      ? const Color(0xFF2C2354)
      : context.colors.outlineVariant;
}

/// Geri oku solda, başlık ortada, isteğe bağlı sağ eylem(ler) olan ekran iskeleti.
class MockScaffold extends StatelessWidget {
  const MockScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.onBack,
    this.showBack = true,
    this.bottom,
    this.startAligned = false,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? bottom;
  final bool startAligned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              MockAppBar(
                title: title,
                actions: actions,
                showBack: showBack,
                onBack: onBack,
                startAligned: startAligned,
              ),
              Expanded(child: body),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }
}

class MockAppBar extends StatelessWidget {
  const MockAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.onBack,
    this.showBack = true,
    this.startAligned = false,
  });

  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBack;
  final bool startAligned;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Align(
            alignment: startAligned
                ? AlignmentDirectional.centerStart
                : Alignment.center,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: startAligned ? 52 : 56,
                end: 56,
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: startAligned ? TextAlign.start : TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.onSurface,
                ),
              ),
            ),
          ),
          if (showBack)
            PositionedDirectional(
              start: 4,
              child: IconButton(
                tooltip: 'Geri',
                icon: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 30,
                ),
                color: c.onSurface,
                onPressed: onBack ?? () => Navigator.maybePop(context),
              ),
            ),
          if (actions.isNotEmpty)
            PositionedDirectional(
              end: 4,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
        ],
      ),
    );
  }
}

/// Düz renkli, beyaz ikonlu yuvarlatılmış kare.
class MockIconSquare extends StatelessWidget {
  const MockIconSquare({
    super.key,
    required this.icon,
    required this.color,
    this.size = 30,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.18)!, color],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.58),
    );
  }
}

/// Tek satırlık kart: ikon karesi + başlık/alt başlık + sağda değer/ok/anahtar.
class MockListRow extends StatelessWidget {
  const MockListRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.value,
    this.valueColor,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.chevron = true,
    this.dense = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool chevron;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final titleColor = danger ? const Color(0xFFFF5A6A) : c.onSurface;
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: mockCardColor(context),
            borderRadius: radius,
            border: Border.all(
              color: danger
                  ? const Color(0xFFFF5A6A).withValues(alpha: 0.35)
                  : mockCardBorder(context),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: dense ? 6 : 8,
            ),
            child: Row(
              children: [
                MockIconSquare(icon: icon, color: color),
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: c.onSurfaceMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? c.onSurfaceMuted,
                      ),
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else if (chevron && onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: c.onSurfaceMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mor anahtarlı satır.
class MockSwitchRow extends StatelessWidget {
  const MockSwitchRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MockListRow(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeTrackColor: const Color(0xFF8B5CF6),
        activeThumbColor: Colors.white,
      ),
    );
  }
}

/// Satırlar arası standart boşluklu liste gövdesi.
class MockRowList extends StatelessWidget {
  const MockRowList({
    super.key,
    required this.children,
    this.padding = const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 32),
    this.gap = 8,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(height: gap),
      itemBuilder: (_, i) => children[i],
    );
  }
}
