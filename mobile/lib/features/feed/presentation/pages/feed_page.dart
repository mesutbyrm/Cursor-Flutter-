import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bootstrap/feed_barrier_watchdog.dart';
import '../../../home/presentation/pages/home_page.dart';

/// Keşfet sekmesi — canlifal.com ana sayfa düzeni (native API).
class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const FeedBarrierWatchdog(child: HomePage());
  }
}
