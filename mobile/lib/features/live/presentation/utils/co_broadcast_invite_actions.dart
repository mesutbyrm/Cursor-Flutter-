import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../providers/co_broadcast_provider.dart';
import '../providers/live_providers.dart';
import '../providers/pending_co_broadcast_join_provider.dart';
import 'open_live_stream.dart';

/// `GET /api/user/co-broadcast-invites` satırı — yalnızca oturumdaki kullanıcının
/// davetleri döner; `userId` alanı yoktur.
bool isPendingCoBroadcastInvite(Map<String, dynamic> invite, String userId) {
  final status = (invite['status']?.toString() ?? 'pending').toLowerCase();
  if (status != 'pending' && status != 'invited') return false;
  for (final key in const ['inviteeId', 'userId', 'targetUserId', 'guestUserId']) {
    final v = invite[key]?.toString().trim();
    if (v != null && v.isNotEmpty && v != userId) return false;
  }
  return true;
}

String coBroadcastInviteStreamId(Map<String, dynamic> invite) =>
    (invite['streamId'] ?? invite['videoStreamId'] ?? invite['liveStreamId'] ?? '')
        .toString()
        .trim();

String coBroadcastInviteHostName(Map<String, dynamic> invite) {
  final broadcaster = invite['broadcaster'];
  final fromBroadcaster =
      broadcaster is Map ? broadcaster['name']?.toString().trim() : null;
  if (fromBroadcaster != null && fromBroadcaster.isNotEmpty) {
    return fromBroadcaster;
  }
  return (invite['hostName'] ?? invite['streamerName'] ?? invite['fromName'] ?? 'Yayıncı')
      .toString();
}

/// `PATCH /api/video-streams/{id}/co-broadcast {action: accept}` + yayına geçiş.
Future<void> acceptCoBroadcastInviteAndJoin(WidgetRef ref, String streamId) async {
  final notifier = ref.read(coBroadcastProvider.notifier);
  await notifier.acceptInvite(streamId);
  await notifier.refreshStream(streamId);
  ref.read(pendingCoBroadcastJoinProvider.notifier).setPending(streamId);
  final nav = rootNavigatorKey.currentContext;
  if (nav == null || !nav.mounted) return;
  final streams = ref.read(liveStreamsProvider).valueOrNull ?? const [];
  LiveStreamEntity? stream;
  for (final s in streams) {
    if (s.id == streamId) {
      stream = s;
      break;
    }
  }
  if (stream != null) await openLiveStreamSwipe(nav, ref, stream);
}
