import 'package:flutter/material.dart';

import '../../app/router/app_router.dart';
import 'app_startup_log.dart';

/// Yarım kalmış dialog / bottom sheet / geçiş barrier katmanlarını temizler.
abstract final class StuckOverlayGuard {
  /// Üstteki [PopupRoute] veya görünür modal barrier katmanlarını kaldırır.
  static int dismissPopupRoutes(
    GlobalKey<NavigatorState> navigatorKey, {
    String reason = 'manual',
  }) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      AppStartupLog.overlayHide(reason: reason, note: 'nav-null');
      return 0;
    }
    return dismissNavigator(nav, reason: reason);
  }

  static int dismissNavigator(
    NavigatorState nav, {
    String reason = 'manual',
  }) {
    var popped = 0;
    for (var guard = 0; guard < 24; guard++) {
      if (!nav.canPop()) break;
      if (!_shouldPopTopRoute(nav)) break;
      nav.pop();
      popped++;
    }

    final barriers = 0;
    final overlay = nav.overlay;
    if (overlay != null && overlay.mounted) {
      final removed = _scrubOrphanModalBarriers(overlay.context, nav: nav);
      AppStartupLog.overlayHide(
        reason: reason,
        popped: popped,
        canStillPop: nav.canPop(),
        note: removed > 0 ? 'orphan-barriers=$removed' : null,
      );
      return popped + removed;
    }

    AppStartupLog.overlayHide(
      reason: reason,
      popped: popped,
      canStillPop: nav.canPop(),
      note: barriers > 0 ? 'barriers=$barriers' : null,
    );
    return popped;
  }

  /// Kök navigator'da pop edilemeyen yetim [ModalBarrier] katmanları.
  static int _scrubOrphanModalBarriers(
    BuildContext overlayContext, {
    NavigatorState? nav,
  }) {
    final barriers = _collectModalBarrierElements(overlayContext);
    if (barriers.isEmpty) return 0;

    var removed = 0;
    for (final barrier in barriers) {
      if (_removeOverlayEntryFor(barrier)) removed++;
    }
    return removed;
  }

  static List<Element> _collectModalBarrierElements(BuildContext context) {
    final result = <Element>[];
    void visit(Element element) {
      if (element.widget is ModalBarrier) {
        result.add(element);
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return result;
  }

  /// [_OverlayEntryWidget] — private API; yalnızca yetim barrier temizliği.
  static bool _removeOverlayEntryFor(Element barrierElement) {
    Element? overlayEntryElement;
    barrierElement.visitAncestorElements((ancestor) {
      final typeName = ancestor.widget.runtimeType.toString();
      if (typeName == '_OverlayEntryWidget' ||
          typeName == 'OverlayEntryWidget') {
        overlayEntryElement = ancestor;
        return false;
      }
      return true;
    });
    final current = overlayEntryElement;
    if (current == null) return false;
    try {
      final entry = (current.widget as dynamic).entry as OverlayEntry?;
      if (entry != null && entry.mounted) {
        entry.remove();
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  static bool _shouldPopTopRoute(NavigatorState nav) {
    final route = _topRoute(nav);
    if (route == null) return false;
    if (route is PopupRoute) return true;
    if (route is ModalRoute) {
      final barrier = route.barrierColor;
      if (barrier != null && barrier.a > 0) return true;
    }
    return false;
  }

  static Route<dynamic>? _topRoute(NavigatorState nav) {
    Route<dynamic>? top;
    nav.popUntil((route) {
      if (route.isCurrent) top = route;
      return true;
    });
    return top;
  }

  static int dismissRoot({String reason = 'root'}) {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      AppStartupLog.overlayHide(reason: reason, note: 'nav-null');
      return 0;
    }
    return dismissNavigator(nav, reason: reason);
  }

  /// Kök + iç navigator + overlay context (yetim barrier).
  static int dismissAll({
    String reason = 'all',
    NavigatorState? nested,
    BuildContext? overlayContext,
  }) {
    var total = dismissRoot(reason: '$reason-root');
    if (nested != null && nested != rootNavigatorKey.currentState) {
      total += dismissNavigator(nested, reason: '$reason-nested');
    }
    final contexts = <BuildContext>{};
    final rootCtx = overlayContext ?? rootNavigatorKey.currentContext;
    if (rootCtx != null) contexts.add(rootCtx);
    final rootOverlay = rootCtx != null ? Overlay.maybeOf(rootCtx) : null;
    if (rootOverlay != null && rootOverlay.mounted) {
      contexts.add(rootOverlay.context);
    }
    for (final ctx in contexts) {
      total += _scrubOrphanModalBarriers(
        ctx,
        nav: rootNavigatorKey.currentState,
      );
    }
    return total;
  }
}
