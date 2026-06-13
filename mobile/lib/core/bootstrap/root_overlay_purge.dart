import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/router/app_router.dart';
import 'app_startup_log.dart';
import 'startup_route_observer.dart';

/// Kök navigator overlay teşhisi + giriş sonrası zorla temizlik.
abstract final class RootOverlayPurge {
  static Timer? _postLoginTimer;

  static void schedulePostLoginForcePurge({
    Duration delay = const Duration(seconds: 5),
  }) {
    _postLoginTimer?.cancel();
    _postLoginTimer = Timer(delay, () {
      forcePurgeRootNavigatorOverlay(reason: 'post-login-${delay.inSeconds}s');
    });
    AppStartupLog.log(
      'POST_LOGIN_FORCE_PURGE scheduled in ${delay.inSeconds}s',
    );
  }

  static void cancelScheduledPurge() {
    _postLoginTimer?.cancel();
    _postLoginTimer = null;
  }

  /// Anlık overlay anlık görüntüsü (giriş hemen sonrası teşhis).
  static void logRootOverlaySnapshot({required String reason}) {
    _logRouteStack('snapshot-$reason');
    AppStartupLog.log('Overlay snapshot ($reason):');
    for (final line in _describeRootOverlayEntries()) {
      AppStartupLog.log('  $line');
    }
    final blockers = _describeBlockingWidgetsOnScreen();
    if (blockers.isEmpty) {
      AppStartupLog.log('  (no ModalBarrier/AbsorbPointer blockers in tree)');
    } else {
      AppStartupLog.log('  Blocking widgets on screen:');
      for (final b in blockers) {
        AppStartupLog.log('    $b');
      }
    }
    if (BarrierRouteJournal.entries.isNotEmpty) {
      AppStartupLog.log(
        '  Recent barrier routes (journal): ${BarrierRouteJournal.entries.join(' | ')}',
      );
    }
  }

  /// Login başarılı + [delay] sonra — tüm barrier içeren overlay entry'leri kaldır.
  static int forcePurgeRootNavigatorOverlay({required String reason}) {
    final nav = rootNavigatorKey.currentState;
    final overlay = nav?.overlay;
    if (nav == null || overlay == null || !overlay.mounted) {
      AppStartupLog.log('FORCE_PURGE skipped: root navigator/overlay null');
      return 0;
    }

    _logRouteStack(reason);

    AppStartupLog.log('Overlay entries before purge:');
    final before = _describeRootOverlayEntries();
    if (before.isEmpty) {
      AppStartupLog.log('  (empty)');
    } else {
      for (final line in before) {
        AppStartupLog.log('  $line');
      }
    }

    var removedEntries = 0;
    var removedBarriers = 0;

    // 1) Popup/dialog route'ları güvenli pop
    for (var i = 0; i < 16; i++) {
      if (!nav.canPop()) break;
      final route = _currentRoute(nav);
      if (route == null || !_routeHasBarrier(route)) break;
      AppStartupLog.log(
        'FORCE_PURGE pop route=${route.settings.name ?? route.runtimeType}',
      );
      nav.pop();
    }

    // 2) Kök overlay'deki barrier içeren OverlayEntry'leri zorla kaldır
    final entries = _collectRootOverlayEntryElements(overlay);
    for (var i = entries.length - 1; i >= 0; i--) {
      final item = entries[i];
      if (!item.hasModalBarrier) continue;
      final attribution = _attributeBarrierInEntry(item, nav);
      AppStartupLog.log(
        'FORCE_PURGE remove entry[$i] attribution=$attribution '
        'widgets=${item.widgetTypes.join('>')}',
      );
      if (_removeOverlayEntryElement(item.element)) {
        removedEntries++;
      }
    }

    // 3) Ağaçta kalan yetim ModalBarrier
    removedBarriers += _scrubOrphanBarriersInTree();

    AppStartupLog.log('Overlay entries after purge:');
    final after = _describeRootOverlayEntries();
    if (after.isEmpty) {
      AppStartupLog.log('  (empty)');
    } else {
      for (final line in after) {
        AppStartupLog.log('  $line');
      }
    }

    final blockers = _describeBlockingWidgetsOnScreen();
    AppStartupLog.log('Remaining blocking widgets on screen:');
    if (blockers.isEmpty) {
      AppStartupLog.log('  (none)');
    } else {
      for (final b in blockers) {
        AppStartupLog.log('  $b');
      }
    }

    if (BarrierRouteJournal.entries.isNotEmpty) {
      AppStartupLog.log(
        'Barrier route journal (likely sources): '
        '${BarrierRouteJournal.entries.join(' | ')}',
      );
    }

    AppStartupLog.log(
      'FORCE_PURGE done reason=$reason removedEntries=$removedEntries '
      'removedBarriers=$removedBarriers',
    );
    return removedEntries + removedBarriers;
  }

  static void _logRouteStack(String reason) {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      AppStartupLog.log('ROUTE_STACK ($reason): nav=null');
      return;
    }
    final lines = <String>[];
    nav.popUntil((route) {
      final modal = route is ModalRoute ? route : null;
      final barrier = modal?.barrierColor;
      lines.add(
        '${route.settings.name ?? route.runtimeType} '
        'current=${route.isCurrent} active=${route.isActive} '
        'barrier=$barrier',
      );
      return true;
    });
    AppStartupLog.log('ROUTE_STACK ($reason): ${lines.join(' → ')}');
  }

  static Route<dynamic>? _currentRoute(NavigatorState nav) {
    Route<dynamic>? top;
    nav.popUntil((route) {
      if (route.isCurrent) top = route;
      return true;
    });
    return top;
  }

  static bool _routeHasBarrier(Route<dynamic> route) {
    if (route is PopupRoute) return true;
    if (route is ModalRoute) {
      final c = route.barrierColor;
      return c != null && c.a > 0;
    }
    return false;
  }

  static List<String> _describeRootOverlayEntries() {
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null || !overlay.mounted) {
      return ['(overlay unavailable)'];
    }
    final items = _collectRootOverlayEntryElements(overlay);
    if (items.isEmpty) return [];

    return [
      for (var i = 0; i < items.length; i++)
        _formatEntryLine(i, items[i], rootNavigatorKey.currentState),
    ];
  }

  static String _formatEntryLine(
    int index,
    _OverlayEntryInspect item,
    NavigatorState? nav,
  ) {
    final mounted = item.entry?.mounted ?? true;
    final attribution = item.hasModalBarrier
        ? _attributeBarrierInEntry(item, nav)
        : 'no-barrier';
    return '[$index] mounted=$mounted '
        'widgets=${item.widgetTypes.join('>')} '
        'hasModalBarrier=${item.hasModalBarrier} '
        'attribution=$attribution';
  }

  static String _attributeBarrierInEntry(
    _OverlayEntryInspect item,
    NavigatorState? nav,
  ) {
    final barrierEl = item.modalBarrierElement;
    if (barrierEl != null) {
      final route = ModalRoute.of(barrierEl);
      if (route != null) {
        return 'ModalRoute:${route.runtimeType} '
            'name=${route.settings.name} '
            'barrier=${route.barrierColor}';
      }
    }

    // Journal — son push edilen barrier route'ları
    final journal = BarrierRouteJournal.entries;
    if (journal.isNotEmpty) {
      return 'ORPHAN (no ModalRoute.of) suspected=${journal.last}';
    }
    return 'ORPHAN (no ModalRoute.of, empty journal)';
  }

  static List<_OverlayEntryInspect> _collectRootOverlayEntryElements(
    OverlayState overlay,
  ) {
    final result = <_OverlayEntryInspect>[];
    overlay.context.visitChildElements((element) {
      final typeName = element.widget.runtimeType.toString();
      if (!_isOverlayEntryWidget(typeName)) return;

      OverlayEntry? entry;
      try {
        entry = (element.widget as dynamic).entry as OverlayEntry?;
      } catch (_) {}

      final widgetTypes = <String>[];
      Element? barrierEl;
      void visitDescendants(Element el) {
        final t = el.widget.runtimeType.toString();
        widgetTypes.add(t);
        if (el.widget is ModalBarrier) {
          barrierEl ??= el;
        }
        el.visitChildren(visitDescendants);
      }

      element.visitChildren(visitDescendants);

      result.add(
        _OverlayEntryInspect(
          element: element,
          entry: entry,
          widgetTypes: widgetTypes,
          hasModalBarrier: barrierEl != null,
          modalBarrierElement: barrierEl,
        ),
      );
    });
    return result;
  }

  static bool _isOverlayEntryWidget(String typeName) {
    return typeName == '_OverlayEntryWidget' ||
        typeName.contains('OverlayEntry');
  }

  static bool _removeOverlayEntryElement(Element entryElement) {
    try {
      final entry = (entryElement.widget as dynamic).entry as OverlayEntry?;
      if (entry != null && entry.mounted) {
        entry.remove();
        return true;
      }
    } catch (_) {}
    return false;
  }

  static int _scrubOrphanBarriersInTree() {
    var removed = 0;
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return 0;

    final barriers = <Element>[];
    void visit(Element element) {
      if (element.widget is ModalBarrier) {
        barriers.add(element);
      }
      element.visitChildren(visit);
    }

    visit(root);

    for (final barrier in barriers) {
      final route = ModalRoute.of(barrier);
      AppStartupLog.log(
        'FORCE_PURGE orphan barrier widget=${barrier.widget.runtimeType} '
        'route=${route?.settings.name ?? route?.runtimeType ?? "ORPHAN"}',
      );
      if (_removeOverlayEntryForBarrier(barrier)) removed++;
    }
    return removed;
  }

  static bool _removeOverlayEntryForBarrier(Element barrierElement) {
    Element? overlayEntryElement;
    barrierElement.visitAncestorElements((ancestor) {
      final typeName = ancestor.widget.runtimeType.toString();
      if (_isOverlayEntryWidget(typeName)) {
        overlayEntryElement = ancestor;
        return false;
      }
      return true;
    });
    final current = overlayEntryElement;
    if (current == null) return false;
    return _removeOverlayEntryElement(current);
  }

  /// Ekranda dokunmayı engelleyebilecek widget'lar — tam sınıf adı.
  static List<String> _describeBlockingWidgetsOnScreen() {
    final blockers = <String>[];
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return blockers;

    void visit(Element element, int depth) {
      if (depth > 40) return;
      final widget = element.widget;

      if (widget is ModalBarrier) {
        final route = ModalRoute.of(element);
        final render = element.renderObject;
        final size = render is RenderBox && render.hasSize
            ? render.size
            : Size.zero;
        blockers.add(
          '${widget.runtimeType} '
          'color=${widget.color} dismissible=${widget.dismissible} '
          'size=${size.width.toInt()}x${size.height.toInt()} '
          'route=${route?.settings.name ?? route?.runtimeType ?? "ORPHAN"}',
        );
      } else if (widget is AbsorbPointer && widget.absorbing) {
        blockers.add(
          '${widget.runtimeType} absorbing=true child=${widget.child.runtimeType}',
        );
      } else if (widget is BlockSemantics) {
        blockers.add('${widget.runtimeType} blocking=true');
      }

      element.visitChildren((child) => visit(child, depth + 1));
    }

    visit(root, 0);
    return blockers;
  }
}

final class _OverlayEntryInspect {
  const _OverlayEntryInspect({
    required this.element,
    required this.entry,
    required this.widgetTypes,
    required this.hasModalBarrier,
    required this.modalBarrierElement,
  });

  final Element element;
  final OverlayEntry? entry;
  final List<String> widgetTypes;
  final bool hasModalBarrier;
  final Element? modalBarrierElement;
}

/// Barrier oluşturan route'lar — purge sırasında kaynak tespiti.
abstract final class BarrierRouteJournal {
  static final List<String> entries = [];

  static void recordPush(Route<dynamic> route) {
    final modal = route is ModalRoute ? route : null;
    final barrier = modal?.barrierColor;
    if (route is PopupRoute || (barrier != null && barrier.a > 0)) {
      final label =
          '${route.runtimeType}@${route.hashCode} '
          'name=${route.settings.name} barrier=$barrier';
      entries.add(label);
      if (entries.length > 24) entries.removeAt(0);
      AppStartupLog.log('BARRIER_JOURNAL push $label');
    }
  }

  static void recordPop(Route<dynamic> route) {
    final suffix = '@${route.hashCode}';
    entries.removeWhere((e) => e.contains(suffix));
    AppStartupLog.log(
      'BARRIER_JOURNAL pop ${route.runtimeType} name=${route.settings.name}',
    );
  }

  static void clear() {
    entries.clear();
  }
}
