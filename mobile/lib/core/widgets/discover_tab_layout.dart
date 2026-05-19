import 'package:flutter/material.dart';

import '../theme/app_design.dart';
import '../../features/feed/presentation/widgets/discover/discover_background.dart';

/// Sekme sayfaları için ortak iskelet (keşfet ile aynı görsel dil).
class DiscoverTabPage extends StatelessWidget {
  const DiscoverTabPage({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.onRefresh,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 100),
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;
  final Future<void> Function()? onRefresh;
  final PreferredSizeWidget? bottom;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: top + 8),
        DiscoverTabHeader(
          title: title,
          subtitle: subtitle,
          actions: actions,
        ),
        if (bottom != null) bottom!,
        Expanded(
          child: Padding(
            padding: padding,
            child: body,
          ),
        ),
      ],
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        color: AppDesign.accentPink,
        backgroundColor: AppDesign.bgPurpleGlow,
        onRefresh: onRefresh!,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: top + 8),
                  DiscoverTabHeader(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                  ),
                  if (bottom != null) bottom!,
                  Expanded(child: Padding(padding: padding, child: body)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      body: DiscoverBackground(child: content),
    );
  }
}

/// Scrollable tab body variant.
class DiscoverTabScrollPage extends StatelessWidget {
  const DiscoverTabScrollPage({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.actions = const [],
    this.onRefresh,
    this.bottom,
    this.scrollController,
    this.onScrollNotification,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;
  final PreferredSizeWidget? bottom;
  final ScrollController? scrollController;
  final bool Function(ScrollNotification)? onScrollNotification;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    Widget scrollView = CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
              SliverToBoxAdapter(child: SizedBox(height: top + 8)),
              SliverToBoxAdapter(
                child: DiscoverTabHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                ),
              ),
              if (bottom != null) SliverToBoxAdapter(child: bottom!),
              ...slivers,
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + 100,
                ),
              ),
            ],
    );

    if (onScrollNotification != null) {
      scrollView = NotificationListener<ScrollNotification>(
        onNotification: onScrollNotification!,
        child: scrollView,
      );
    }

    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      body: DiscoverBackground(
        child: RefreshIndicator(
          color: AppDesign.accentPink,
          backgroundColor: AppDesign.bgPurpleGlow,
          onRefresh: onRefresh ?? () async {},
          child: scrollView,
        ),
      ),
    );
  }
}

/// Geri butonlu tam ekran (bildirim, sohbet, kullanıcı profili).
class DiscoverSubPage extends StatelessWidget {
  const DiscoverSubPage({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.onRefresh,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: top + 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              DiscoverIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: DiscoverTabHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        color: AppDesign.accentPink,
        backgroundColor: AppDesign.bgPurpleGlow,
        onRefresh: onRefresh!,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: top + 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        DiscoverIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: DiscoverTabHeader(
                            title: title,
                            subtitle: subtitle,
                            actions: actions,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverFillRemaining(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      body: DiscoverBackground(child: content),
    );
  }
}

class DiscoverTabHeader extends StatelessWidget {
  const DiscoverTabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppDesign.heroGradient.createShader(b),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppDesign.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class DiscoverIconButton extends StatelessWidget {
  const DiscoverIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppDesign.textSecondary, size: 24),
      ),
    );
  }
}

class DiscoverGlassCard extends StatelessWidget {
  const DiscoverGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppDesign.accentPurple.withValues(alpha: 0.28);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        color: const Color(0xFF16162A).withValues(alpha: 0.88),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        child: content,
      ),
    );
  }
}

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DiscoverGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppDesign.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppDesign.textSecondary,
                height: 1.4,
                fontSize: 15,
              ),
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: action,
                style: FilledButton.styleFrom(
                  backgroundColor: AppDesign.accentPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DiscoverAccentLoader extends StatelessWidget {
  const DiscoverAccentLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppDesign.accentPink,
        ),
      ),
    );
  }
}

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
            color: AppDesign.accentPurple.withValues(alpha: 0.25),
          ),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppDesign.heroGradient,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppDesign.textMuted,
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
