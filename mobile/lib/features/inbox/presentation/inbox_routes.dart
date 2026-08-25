import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/inbox_tab.dart';

/// Gelen kutusu rotaları — mesaj + sistem bildirimi tek giriş.
abstract final class InboxRoutes {
  static const path = '/messages';

  static String pathForTab([InboxTab tab = InboxTab.all]) {
    if (tab == InboxTab.all) return path;
    return '$path?tab=${tab.queryValue}';
  }

  static void open(BuildContext context, {InboxTab tab = InboxTab.all}) {
    context.push(pathForTab(tab));
  }
}
