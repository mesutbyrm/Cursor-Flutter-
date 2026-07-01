import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shorts_playback_providers.dart';

Future<void> showShortPlaybackSpeedSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(shortPlaybackSpeedProvider);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF121218),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Oynatma hızı',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          for (final speed in shortPlaybackSpeedOptions)
            ListTile(
              title: Text('${speed}x'),
              trailing: current == speed
                  ? const Icon(Icons.check, color: Colors.amber)
                  : null,
              onTap: () {
                ref.read(shortPlaybackSpeedProvider.notifier).state = speed;
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}
