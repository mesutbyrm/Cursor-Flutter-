import 'package:flutter/material.dart';

import '../performance/list_perf.dart';

/// Görünür öğe sayısı ile istemci tarafı lazy loading (API sayfalama yoksa).
class LazyVisibleListController extends ChangeNotifier {
  LazyVisibleListController({
    int? pageSize,
    int? initialVisible,
  })  : pageSize = pageSize ?? ListPerf.defaultPageSize,
        _visible = initialVisible ?? ListPerf.defaultPageSize;

  final int pageSize;
  int _visible;
  int _total = 0;
  bool _loadingMore = false;

  int get visibleCount => _visible;
  int get total => _total;
  bool get hasMore => _visible < _total;
  bool get isLoadingMore => _loadingMore;

  void reset(int total) {
    _total = total;
    _visible = pageSize.clamp(0, total);
    if (_visible == 0 && total > 0) {
      _visible = total.clamp(0, pageSize);
    }
    notifyListeners();
  }

  void loadMore() {
    if (_loadingMore || !hasMore) return;
    _loadingMore = true;
    _visible = (_visible + pageSize).clamp(0, _total);
    _loadingMore = false;
    notifyListeners();
  }
}

/// [ScrollController] ile uçta `loadMore` tetikler.
mixin LazyScrollPagination<T extends StatefulWidget> on State<T> {
  ScrollController? lazyScrollController;
  LazyVisibleListController? lazyList;

  void initLazyPagination({
    required LazyVisibleListController list,
    ScrollController? controller,
    bool ownController = true,
  }) {
    lazyList = list;
    lazyScrollController = controller ?? ScrollController();
    lazyScrollController!.addListener(_onLazyScroll);
    _ownController = ownController && controller == null;
  }

  var _ownController = true;

  void disposeLazyPagination() {
    lazyScrollController?.removeListener(_onLazyScroll);
    if (_ownController) {
      lazyScrollController?.dispose();
    }
    lazyList = null;
    lazyScrollController = null;
  }

  void _onLazyScroll() {
    final c = lazyScrollController;
    final l = lazyList;
    if (c == null || l == null || !c.hasClients) return;
    if (c.position.pixels >=
        c.position.maxScrollExtent - ListPerf.preloadThresholdPx) {
      l.loadMore();
      if (mounted) setState(() {});
    }
  }
}

/// Sliver liste — yalnızca [visibleCount] kadar öğe build eder.
class LazyPaginatedSliverList extends StatefulWidget {
  const LazyPaginatedSliverList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.controller,
    this.separatorHeight = 10,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final LazyVisibleListController controller;
  final double separatorHeight;

  @override
  State<LazyPaginatedSliverList> createState() =>
      _LazyPaginatedSliverListState();
}

class _LazyPaginatedSliverListState extends State<LazyPaginatedSliverList> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    widget.controller.reset(widget.itemCount);
  }

  @override
  void didUpdateWidget(LazyPaginatedSliverList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      widget.controller.reset(widget.itemCount);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.controller.visibleCount.clamp(0, widget.itemCount);
    final showLoader = widget.controller.hasMore;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i >= visible) {
            if (showLoader && i == visible) {
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
            return null;
          }
          return Padding(
            padding: EdgeInsets.only(bottom: widget.separatorHeight),
            child: ListPerf.repaint(widget.itemBuilder(context, i)),
          );
        },
        childCount: visible + (showLoader ? 1 : 0),
      ),
    );
  }
}
