import 'package:flutter/material.dart';

import '../../../inbox/domain/inbox_tab.dart';
import '../../../inbox/presentation/pages/inbox_page.dart';

/// Geriye dönük uyumluluk — `/notifications` artık gelen kutusu Sistem sekmesine yönlenir.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InboxPage(initialTab: InboxTab.system);
  }
}
