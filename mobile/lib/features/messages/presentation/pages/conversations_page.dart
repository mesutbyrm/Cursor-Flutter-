import 'package:flutter/material.dart';

import '../../inbox/domain/inbox_tab.dart';
import '../../inbox/presentation/pages/inbox_page.dart';

/// Geriye dönük uyumluluk — eski `/messages` rotası [InboxPage]'e yönlendirildi.
class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key, this.initialTab = InboxTab.messages});

  final InboxTab initialTab;

  @override
  Widget build(BuildContext context) {
    return InboxPage(initialTab: initialTab);
  }
}
