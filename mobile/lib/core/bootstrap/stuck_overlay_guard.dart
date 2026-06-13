import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/router/app_router.dart';
import 'app_startup_log.dart';

/// Yarım kalmış dialog / bottom sheet / geçiş barrier katmanlarını temizler.
abstract final class StuckOverlayGuard {
  /// Üstteki dialog / bottom-sheet route'larını güvenli şekilde kapatır.
  /// Private overlay API kullanmaz — yetim barrier oluşturmaz.
  static int popDialogRoutes(
    GlobalKey<NavigatorState> navigatorKey, {
    String reason = 'pop-dialogs',
  }) {
    final nav = navigatorKey.currentState;
    if (nav == null) return 0;
    var popped = 0;
    for (var guard = 0; guard < 12; guard++) {
      if (!nav.canPop()) break;
      final route = _topRoute(nav);
      if (route == null || !_isDialogRoute(route)) break;
      nav.pop();
      popped++;
    }
    if (popped > 0) {
      AppStartupLog.overlayHide(reason: reason, popped: popped);
    }
    return popped;
  }

  static bool _isDialogRoute(Route<dynamic> route) {
    if (route is PopupRoute) return true;
    if (route is ModalRoute) {
      final barrier = route.barrierColor;
      return barrier != null && barrier.a > 0;
    }
    return false;
  }

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
    bool aggressive = false,
  }) {
    var popped = 0;
    for (var guard = 0; guard < 24; guard++) {
      if (!nav.canPop()) break;
      if (!aggressive && !_shouldPopTopRoute(nav)) break;
      nav.pop();
      popped++;
    }

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

  /// Tüm uygulama ağacında yetim barrier ara (kök + iç overlay'ler).
  static int scrubEntireAppTree({String reason = 'tree'}) {
    var removed = 0;
    final root = WidgetsBinding.instance.rootElement;
    if (root != null) {
      void visit(Element element) {
        if (element.widget is ModalBarrier) {
          if (_removeOverlayEntryFor(element)) removed++;
        }
        element.visitChildren(visit);
      }

      visit(root);
    }

    for (final nav in _collectNavigators()) {
      removed += dismissNavigator(nav, reason: '$reason-nav', aggressive: true);
    }

    if (removed > 0) {
      AppStartupLog.overlayHide(reason: reason, note: 'tree-removed=$removed');
    }
    return removed;
  }

  static List<NavigatorState> _collectNavigators() {
    final result = <NavigatorState>[];
    final rootNav = rootNavigatorKey.currentState;
    if (rootNav != null) result.add(rootNav);

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return result;

    void visit(Element element) {
      final state = element;
      if (state is StatefulElement && state.state is NavigatorState) {
        final nav = state.state as NavigatorState;
        if (!result.contains(nav)) result.add(nav);
      }
      element.visitChildren(visit);
    }

    root.visitChildren(visit);
    return result;
  }

  /// [_OverlayEntryWidget] — private API; yalnızca yetim barrier temizliği.
  static bool _removeOverlayEntryFor(Element barrierElement) {
    Element? overlayEntryElement;
    barrierElement.visitAncestorElements((ancestor) {
      final typeName = ancestor.widget.runtimeType.toString();
      if (typeName.contains('OverlayEntry') ||
          typeName == '_OverlayEntryWidget') {
        overlayEntryElement = ancestor;
        return false;
      }
      return true;
    });
    final current = overlayEntryElement;
    if (current != null) {
      try {
        final entry = (current.widget as dynamic).entry as OverlayEntry?;
        if (entry != null && entry.mounted) {
          entry.remove();
          return true;
        }
      } catch (_) {
        return false;
      }
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

  static int dismissRoot({
    String reason = 'root',
    bool aggressive = false,
  }) {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      AppStartupLog.overlayHide(reason: reason, note: 'nav-null');
      return 0;
    }
    return dismissNavigator(nav, reason: reason, aggressive: aggressive);
  }

  /// Kök + iç navigator + tüm uygulama ağacı.
  static int dismissAll({
    String reason = 'all',
    NavigatorState? nested,
    BuildContext? overlayContext,
    bool aggressive = false,
  }) {
    var total = dismissRoot(reason: '$reason-root', aggressive: aggressive);
    if (nested != null && nested != rootNavigatorKey.currentState) {
      total += dismissNavigator(nested, reason: '$reason-nested', aggressive: aggressive);
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
    total += scrubEntireAppTree(reason: '$reason-tree');
    return total;
  }

  /// Giriş sonrası yetim barrier — yalnızca pop edilebilir dialog route'ları kapatır.
  /// Private overlay API kullanılmaz (çift remove → gri ekran).
  static int recoverOrphanBarriersOnce({String reason = 'recover-once'}) {
    final before = _barrierCount();
    if (before == 0) return 0;

    final removed = popDialogRoutes(rootNavigatorKey, reason: reason);
    final after = _barrierCount();
    if (before != after || removed > 0) {
      AppStartupLog.overlayHide(
        reason: reason,
        popped: removed,
        note: 'barriers $before→$after',
      );
    }
    return removed;
  }

  /// Giriş sonrası yetim barrier temizliği + teşhis logu.
  static void purgeAfterLogin({String reason = 'post-login'}) {
    final before = _barrierCount();
    final popped = popDialogRoutes(rootNavigatorKey, reason: reason);
    var scrubbed = 0;
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay != null && overlay.mounted) {
      scrubbed = _scrubOrphanModalBarriers(overlay.context);
    }
    final root = WidgetsBinding.instance.rootElement;
    if (root != null) {
      void visit(Element element) {
        if (element.widget is ModalBarrier) {
          if (_removeOverlayEntryFor(element)) scrubbed++;
        }
        element.visitChildren(visit);
      }

      visit(root);
    }
    final after = _barrierCount();
    AppStartupLog.log(
      'POST_LOGIN_PURGE reason=$reason before=$before popped=$popped '
      'scrubbed=$scrubbed after=$after canPop=${rootNavigatorKey.currentState?.canPop()}',
    );
  }

  /// /feed üzerinde sürekli barrier izleme — post-frame döngüsü.
  static void armFeedBarrierWatch({
    required VoidCallback onDone,
    Duration maxDuration = const Duration(seconds: 45),
  }) {
    final started = DateTime.now();
    void tick(Duration _) {
      final elapsed = DateTime.now().difference(started);
      final removed = dismissAll(reason: 'feed-watch', aggressive: true);
      final barriersLeft = _barrierCount();
      if (barriersLeft == 0 || elapsed >= maxDuration) {
        onDone();
        return;
      }
      if (removed > 0 || elapsed < maxDuration) {
        SchedulerBinding.instance.scheduleFrameCallback(tick);
      } else {
        onDone();
      }
    }

    SchedulerBinding.instance.scheduleFrameCallback(tick);
  }

  static int _barrierCount() {
    var count = 0;
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return 0;
    void visit(Element element) {
      if (element.widget is ModalBarrier) count++;
      element.visitChildren(visit);
    }

    visit(root);
    return count;
  }
}
