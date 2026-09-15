import 'package:flutter/material.dart';

import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';

/// Admin komuta merkezi sekmeleri — ortak liste sarmalayıcı.
class AdminHubTabScroll extends StatelessWidget {
  const AdminHubTabScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: children,
    );
  }
}

Widget adminHubEmpty(String message) {
  return Center(
    child: PlatformSocialEmptyState(
      icon: Icons.inbox_outlined,
      message: message,
    ),
  );
}

/// Cam kart içinde bölüm + satırlar.
class AdminHubSectionCard extends StatelessWidget {
  const AdminHubSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PlatformSocialGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlatformSocialSectionTitle(title),
            ...children,
            if (footer != null) ...[
              const SizedBox(height: 8),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Yetki / moderasyon satırı.
class AdminHubActionRow extends StatelessWidget {
  const AdminHubActionRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return PlatformSocialListRow(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? PlatformSocialPalette.accent),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded, color: Colors.white38)
          : null,
    );
  }
}
