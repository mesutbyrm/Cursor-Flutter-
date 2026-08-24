import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/network/token_storage.dart';
import '../../data/services/live_namespace_socket_service.dart';
import '../providers/live_providers.dart';
import 'live_pk_invite_signal_provider.dart';
import 'live_pk_streams_provider.dart';
import 'pk_room_providers.dart';

final livePkGlobalNamespaceSocketProvider =
    Provider<LiveNamespaceSocketService>((ref) {
  final svc = LiveNamespaceSocketService();
  ref.onDispose(svc.disconnect);
  return svc;
});

/// Kullanıcının canlı yayınları için global PK socket — HTTP polling yok.
final livePkOwnedStreamsSocketProvider = Provider<void>((ref) {
  void sync() {
    final user = ref.read(authControllerProvider).valueOrNull;
    final socket = ref.read(livePkGlobalNamespaceSocketProvider);
    if (user == null) {
      socket.disconnect();
      return;
    }
    final streams = ref.read(liveStreamsProvider).valueOrNull ?? const [];
    final ids = streams
        .where((s) {
          if (!s.isLive) return false;
          final host = s.hostUserId?.trim() ?? '';
          return host.isNotEmpty && host == user.id;
        })
        .map((s) => s.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) {
      socket.disconnect();
      return;
    }
    final storage = ref.read(tokenStorageProvider);
    socket.connect(
      accessToken: storage.readAccess,
      streamIds: ids,
      onPkInvite: (_) {
        ref.invalidate(pkPendingInvitesProvider);
        ref.invalidate(livePkStreamsProvider);
        ref.read(livePkInviteSignalProvider.notifier).bump();
      },
    );
  }

  ref.listen(liveStreamsProvider, (_, __) => sync());
  ref.listen(authControllerProvider, (_, __) => sync());
  ref.onDispose(() {
    ref.read(livePkGlobalNamespaceSocketProvider).disconnect();
  });
  Future.microtask(sync);
});
