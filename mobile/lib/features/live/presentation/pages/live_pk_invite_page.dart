import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../providers/live_providers.dart';

/// Canlı yayın PK daveti — karşı yayıncı seçimi.
class LivePkInvitePage extends ConsumerStatefulWidget {
  const LivePkInvitePage({super.key, required this.session});

  final LiveBroadcastSession session;

  @override
  ConsumerState<LivePkInvitePage> createState() => _LivePkInvitePageState();
}

class _LivePkInvitePageState extends ConsumerState<LivePkInvitePage> {
  var _loading = false;
  String? _error;

  String? get _streamId => widget.session.streamId?.trim();

  Future<void> _invite(LiveStreamEntity opponent) async {
    final streamId = _streamId;
    if (streamId == null || streamId.isEmpty) {
      setState(() => _error = 'Yayın kimliği bulunamadı');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final battle = await ref.read(pkBattleRemoteProvider.notifier).inviteStream(
            streamId: streamId,
            opponentStreamId: opponent.id,
          );
      if (!mounted) return;
      if (battle == null) {
        setState(() => _error = 'PK daveti gönderilemedi');
        return;
      }
      context.push(
        '/live/pk',
        extra: {
          'session': widget.session,
          'opponent': opponent,
        },
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamsAsync = ref.watch(liveStreamsProvider);
    final myId = _streamId;

    return Scaffold(
      appBar: AppBar(title: const Text('Canlı PK Daveti')),
      body: streamsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (streams) {
          final others = streams
              .where((s) => s.isLive && s.id != myId)
              .toList();
          if (_error != null) {
            return Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            );
          }
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (others.isEmpty) {
            return const Center(child: Text('PK için uygun canlı yayın yok'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: others.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = others[i];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white12),
                ),
                leading: CircleAvatar(
                  backgroundImage: s.thumbnailUrl != null && s.thumbnailUrl!.isNotEmpty
                      ? NetworkImage(s.thumbnailUrl!)
                      : null,
                  child: s.thumbnailUrl == null || s.thumbnailUrl!.isEmpty
                      ? const Icon(Icons.live_tv_rounded)
                      : null,
                ),
                title: Text(s.title),
                subtitle: Text(
                  '${s.streamerName ?? 'Yayıncı'} · ${s.viewerCount} izleyici',
                ),
                trailing: const Icon(Icons.flash_on_rounded),
                onTap: () => _invite(s),
              );
            },
          );
        },
      ),
    );
  }
}
