import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../pk/data/pk_models.dart';
import '../../../../pk/presentation/providers/pk_session_notifier.dart';
import '../../../../pk/presentation/widgets/pk_pending_banner.dart';

/// Yayıncı — gönderilen PK daveti bekleniyor (iptal).
class LivePkHostPendingBanner extends ConsumerWidget {
  const LivePkHostPendingBanner({
    super.key,
    required this.streamId,
  });

  final String streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = PkSessionArgs(contextId: streamId, kind: PkContextKind.live);
    final session = ref.watch(pkSessionProvider(args));
    final battle = session.battle;
    if (battle == null || battle.status != PkStatus.pending) {
      return const SizedBox.shrink();
    }
    final sid = streamId.trim().toLowerCase();
    final r1 = battle.room1Id.trim().toLowerCase();
    if (r1.isNotEmpty && r1 != sid) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: PkPendingBanner(args: args),
    );
  }
}
