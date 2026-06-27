import 'package:flutter/material.dart';

import '../performance/list_perf.dart';

/// Yatay lazy liste — story şeritleri, canlı yayın karuseli.
class LazyHorizontalListView extends StatelessWidget {
  const LazyHorizontalListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.controller,
    this.physics,
    this.cacheExtent = ListPerf.cacheExtent,
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
      physics: physics ?? ListPerf.listPhysics,
      cacheExtent: cacheExtent,
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          ListPerf.repaint(itemBuilder(context, index)),
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
    this.cacheExtent = ListPerf.cacheExtent,
    this.separatorBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double cacheExtent;
  final IndexedWidgetBuilder? separatorBuilder;

  @override
  Widget build(BuildContext context) {
    if (separatorBuilder != null) {
      return ListView.separated(
        controller: controller,
        padding: padding,
        physics: physics ?? ListPerf.listPhysics,
        cacheExtent: cacheExtent,
        itemCount: itemCount,
        separatorBuilder: (context, index) =>
            ListPerf.repaint(separatorBuilder!(context, index)),
        itemBuilder: (context, index) =>
            ListPerf.repaint(itemBuilder(context, index)),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: physics ?? ListPerf.listPhysics,
      cacheExtent: cacheExtent,
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          ListPerf.repaint(itemBuilder(context, index)),
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
    this.cacheExtent = ListPerf.cacheExtent,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double cacheExtent;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      physics: physics ?? ListPerf.listPhysics,
      cacheExtent: cacheExtent,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          ListPerf.repaint(itemBuilder(context, index)),
    );
  }
}
