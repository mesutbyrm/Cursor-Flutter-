import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/voice_hub/presentation/providers/staff_entrance_marquee_provider.dart';
import '../site_animation_social_bridge.dart';

/// Global marquee VIP giriş → `ctx_social` site animasyon kartı.
class SiteAnimationSocialEntranceListener extends ConsumerWidget {
  const SiteAnimationSocialEntranceListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(staffEntranceMarqueeProvider, (prev, next) {
      final msg = next.message;
      if (msg == null || msg.isEmpty || msg == prev?.message) return;
      dispatchSiteAnimationSocialEntrance(ref, msg);
    });
    return child;
  }
}
