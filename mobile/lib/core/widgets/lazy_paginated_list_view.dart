import 'package:flutter/material.dart';

import '../performance/list_perf.dart';
import 'lazy_paginated_sliver_list.dart';

/// [ListView] — yalnızca görünür dilim build edilir; scroll’da genişler.
class LazyPaginatedListView extends StatefulWidget {
  const LazyPaginatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding = EdgeInsets.zero,
    this.controller,
    this.physics,
    this.cacheExtent = ListPerf.cacheExtent,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double cacheExtent;

  @override
  State<LazyPaginatedListView> createState() => _LazyPaginatedListViewState();
}

class _LazyPaginatedListViewState extends State<LazyPaginatedListView> {
  late final LazyVisibleListController _lazy;
  late final ScrollController _scroll;
  var _ownsScroll = false;

  @override
  void initState() {
    super.initState();
    _lazy = LazyVisibleListController();
    _lazy.addListener(_onLazyChange);
    _ownsScroll = widget.controller == null;
    _scroll = widget.controller ?? ScrollController();
    _scroll.addListener(_onScroll);
    _lazy.reset(widget.itemCount);
  }

  @override
  void didUpdateWidget(LazyPaginatedListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _lazy.reset(widget.itemCount);
    }
  }

  @override
  void dispose() {
    _lazy.removeListener(_onLazyChange);
    _scroll.removeListener(_onScroll);
    _lazy.dispose();
    if (_ownsScroll) _scroll.dispose();
    super.dispose();
  }

  void _onLazyChange() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - ListPerf.preloadThresholdPx) {
      _lazy.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _lazy.visibleCount.clamp(0, widget.itemCount);
    final showLoader = _lazy.hasMore;
    final total = visible + (showLoader ? 1 : 0);

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        controller: _scroll,
        padding: widget.padding,
        physics: widget.physics ?? ListPerf.listPhysics,
        cacheExtent: widget.cacheExtent,
        itemCount: total,
        separatorBuilder: (context, index) {
          if (index >= visible - 1) return const SizedBox.shrink();
          return widget.separatorBuilder!(context, index);
        },
        itemBuilder: (context, index) {
          if (index >= visible) {
            if (showLoader && index == visible) {
              return const _LazyLoaderTile();
            }
            return const SizedBox.shrink();
          }
          return ListPerf.repaint(widget.itemBuilder(context, index));
        },
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: widget.padding,
      physics: widget.physics ?? ListPerf.listPhysics,
      cacheExtent: widget.cacheExtent,
      itemCount: total,
      itemBuilder: (context, index) {
        if (index >= visible) {
          if (showLoader && index == visible) {
            return const _LazyLoaderTile();
          }
          return const SizedBox.shrink();
        }
        return ListPerf.repaint(widget.itemBuilder(context, index));
      },
    );
  }
}

class _LazyLoaderTile extends StatelessWidget {
  const _LazyLoaderTile();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
