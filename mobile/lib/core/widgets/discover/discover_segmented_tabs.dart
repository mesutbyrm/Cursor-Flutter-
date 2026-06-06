import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';


class DiscoverSegmentedTabs extends StatelessWidget implements PreferredSizeWidget {
  const DiscoverSegmentedTabs({
    super.key,
    required this.controller,
    required this.tabs,
  });

  final TabController controller;
  final List<({String label, IconData icon})> tabs;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppThemeColors.accentPurple.withValues(alpha: 0.25),
          ),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: context.colors.brandGradient,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: context.colors.onSurfaceMuted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          dividerColor: Colors.transparent,
          tabs: [
            for (final t in tabs)
              Tab(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 18),
                    const SizedBox(width: 6),
                    Text(t.label),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
