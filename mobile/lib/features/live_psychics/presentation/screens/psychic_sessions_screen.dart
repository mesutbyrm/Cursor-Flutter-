import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/psychics_list_controller.dart';
import '../widgets/psychic_recent_sessions_panel.dart';

/// Falcı — seans geçmişi (`GET /api/fortune-tellers/session`, gerçek veri).
class PsychicSessionsScreen extends ConsumerWidget {
  const PsychicSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seans geçmişi')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(psychicRecentSessionsProvider);
          await ref.read(psychicRecentSessionsProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: const [
            PsychicRecentSessionsPanel(
              title: 'Tamamlanan görüşmeler',
              limit: 50,
            ),
          ],
        ),
      ),
    );
  }
}
