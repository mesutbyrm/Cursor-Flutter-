import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/staff_entrance_marquee_provider.dart';
import 'voice_room/voice_room_staff_join_banner.dart';

/// Uygulama geneli yetkili giriş şeridi — navbar altında, sesli odada kapalı.
class StaffEntranceMarqueeHost extends ConsumerWidget {
  const StaffEntranceMarqueeHost({
    super.key,
    required this.child,
    this.routePath,
  });

  final Widget child;
  final String? routePath;

  static bool hideForRoute(String? location) {
    final path = Uri.tryParse(location ?? '')?.path ?? location ?? '';
    // Sesli odada koltuk altı banner kullanılır; üst şerit çakışmasın.
    return path.startsWith('/voice-room/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(
      staffEntranceMarqueeProvider.select((s) => s.message),
    );
    final location = routePath ??
        GoRouter.maybeOf(context)
            ?.routerDelegate
            .currentConfiguration
            .uri
            .path;
    final hide = hideForRoute(location);
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (!hide && message != null && message.trim().isNotEmpty)
          Positioned(
            top: topInset,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: VoiceRoomStaffJoinBanner(enterBanner: message),
            ),
          ),
      ],
    );
  }
}
