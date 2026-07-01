import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../live/domain/entities/live_gift_catalog.dart';

Future<void> showShortGiftBurst(BuildContext context, String giftId) async {
  final emoji = LiveGiftCatalog.emojiById[giftId] ?? '🎁';
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    pageBuilder: (ctx, _, __) {
      return IgnorePointer(
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 120),
          )
              .animate()
              .scale(
                begin: const Offset(0.2, 0.2),
                end: const Offset(1.4, 1.4),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeOut(delay: 400.ms, duration: 300.ms),
        ),
      );
    },
  );
}
