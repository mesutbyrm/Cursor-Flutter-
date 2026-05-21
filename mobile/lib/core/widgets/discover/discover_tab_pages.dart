import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../discover_refresh.dart';
import '../../../features/feed/presentation/widgets/discover/discover_background.dart';
import 'discover_tab_header.dart';
import 'discover_icon_button.dart';

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
      content = DiscoverRefresh.wrap(
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
      backgroundColor: AppColors.background,
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
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverRefresh.wrap(
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
      content = DiscoverRefresh.wrap(
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
      backgroundColor: AppColors.background,
      body: DiscoverBackground(child: content),
    );
  }
}
