import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pk_session_notifier.dart';

/// Gönderen taraf — yanıt bekleniyor + iptal.
class PkPendingBanner extends ConsumerWidget {
  const PkPendingBanner({super.key, required this.args});

  final PkSessionArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(pkSessionProvider(args));
    final remaining = session.inviteRemaining;
    final sec = remaining?.inSeconds ?? 0;
    final label =
        sec > 0 ? 'Yanıt bekleniyor · ${sec}s' : 'Yanıt bekleniyor…';

    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, color: Color(0xFFFFD700), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: session.loading
                  ? null
                  : () => ref.read(pkSessionProvider(args).notifier).cancel(),
              child: const Text('İptal'),
            ),
          ],
        ),
      ),
    );
  }
}
