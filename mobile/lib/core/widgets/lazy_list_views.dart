import 'package:flutter/material.dart';

import '../performance/scroll_perf.dart';

export '../performance/scroll_perf.dart' show ScrollSurface, ScrollPerf;

/// Yatay lazy liste — story şeritleri, canlı yayın karuseli.
class LazyHorizontalListView extends StatelessWidget {
  const LazyHorizontalListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.controller,
    this.physics,
    this.cacheExtent = ScrollPerf.horizontalCacheExtent,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double cacheExtent;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      controller: controller,
      padding: padding,
      physics: physics ?? ScrollPerf.feedPhysics,
      cacheExtent: cacheExtent,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          ScrollPerf.item(itemBuilder(context, index)),
    );
  }
}

/// Dikey lazy liste — yalnızca görünür satırlar build edilir.
class LazyListView extends StatelessWidget {
  const LazyListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.controller,
    this.physics,
    this.cacheExtent = ScrollPerf.cacheExtent,
    this.separatorBuilder,
    this.reverse = false,
    this.shrinkWrap = false,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double cacheExtent;
  final IndexedWidgetBuilder? separatorBuilder;
  final bool reverse;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    if (separatorBuilder != null) {
      return ListView.separated(
        controller: controller,
        padding: padding,
        physics: physics ?? ScrollPerf.feedPhysics,
        cacheExtent: cacheExtent,
        reverse: reverse,
        shrinkWrap: shrinkWrap,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemCount: itemCount,
        separatorBuilder: (context, index) =>
            ScrollPerf.item(separatorBuilder!(context, index)),
        itemBuilder: (context, index) =>
            ScrollPerf.item(itemBuilder(context, index)),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: physics ?? ScrollPerf.feedPhysics,
      cacheExtent: cacheExtent,
      reverse: reverse,
      shrinkWrap: shrinkWrap,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          ScrollPerf.item(itemBuilder(context, index)),
    );
  }
}

/// Lazy [GridView.builder] — profil grid, komut paneli vb.
class LazyGridView extends StatelessWidget {
  const LazyGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding,
    this.controller,
    this.physics,
    this.cacheExtent = ScrollPerf.gridCacheExtent,
    this.shrinkWrap = false,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double cacheExtent;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      physics: physics ?? ScrollPerf.feedPhysics,
      cacheExtent: cacheExtent,
      shrinkWrap: shrinkWrap,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          ScrollPerf.item(itemBuilder(context, index)),
    );
  }
}

/// Profil / ana sayfa içindeki sabit yükseklikli grid (parent scroll ile).
class LazyNestedGridView extends StatelessWidget {
  const LazyNestedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding,
    this.cacheExtent = ScrollPerf.gridCacheExtent,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final double cacheExtent;

  @override
  Widget build(BuildContext context) {
    return LazyGridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      cacheExtent: cacheExtent,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
