import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/girlive_rules_notice_provider.dart';

/// GirLive Bot kural hatırlatmasını (yalnızca odaya giren kullanıcıya) kısa,
/// kapatılabilir bir bildirim olarak gösterir.
class GirLiveRulesListener extends ConsumerWidget {
  const GirLiveRulesListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<GirLiveRulesNotice?>(girLiveRulesNoticeProvider, (_, next) {
      if (next == null) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 7),
          showCloseIcon: true,
          content: Text(next.text),
        ),
      );
    });
    return child;
  }
}
