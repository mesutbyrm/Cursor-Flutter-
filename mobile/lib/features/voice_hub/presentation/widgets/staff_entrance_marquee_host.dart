import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/staff_entrance_marquee_provider.dart';
import 'voice_room/voice_room_staff_join_banner.dart';

/// Uygulama geneli yetkili giriş şeridi — aktif sayfanın üstünde, geçici.
class StaffEntranceMarqueeHost extends ConsumerWidget {
  const StaffEntranceMarqueeHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(
      staffEntranceMarqueeProvider.select((s) => s.message),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (message != null && message.trim().isNotEmpty)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 4,
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
