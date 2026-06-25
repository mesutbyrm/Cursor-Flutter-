import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../../voice_hub/domain/pk/pk_duration_options.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_duration_picker.dart';
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
  var _durationSeconds = pkDefaultDurationSeconds;
  String? _error;

  String? get _streamId => widget.session.streamId?.trim();

  @override
  void initState() {
    super.initState();
    // liveStreamsProvider artık autoDispose (bkz. live_providers.dart),
    // ama bu sayfaya gelmeden önce liveStreamsProvider'ı zaten dinleyen
    // başka bir widget (ör. ana sayfa) aktifse provider dispose olmaz,
    // cache korunur. Bu yüzden PK daveti için karşı tarafın o ANKİ
    // canlı yayın durumunu garanti etmek üzere burada da açıkça
    // invalidate ediyoruz — çift güvence, zararsız.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(liveStreamsProvider);
    });
  }

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
            durationSeconds: _durationSeconds,
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
      appBar: AppBar(
        title: const Text('Canlı PK Daveti'),
        actions: [
          // Manuel yenileme — kullanıcı karşı tarafın yeni başlattığı
          // yayını listede görmüyorsa elle tazeleyebilsin diye.
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Listeyi yenile',
            onPressed: () => ref.invalidate(liveStreamsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(liveStreamsProvider);
          // invalidate senkron olduğu için, yeni future'ın en azından
          // başlamasına izin vermek üzere bir sonraki frame'i bekleriz.
          await ref.read(liveStreamsProvider.future).catchError((_) => <LiveStreamEntity>[]);
        },
        child: streamsAsync.when(
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
              // Liste boşsa, eskiden cache'lenmiş veriden mi yoksa
              // gerçekten aktif yayın olmadığından mı emin olamayan
              // kullanıcı için yenileme ipucu veriyoruz.
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('PK için uygun canlı yayın yok')),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Aşağı çekerek listeyi yenileyebilirsiniz',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: others.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return PkDurationPicker(
                    selectedSeconds: _durationSeconds,
                    onChanged: (s) => setState(() => _durationSeconds = s),
                  );
                }
                final s = others[i - 1];
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
      ),
    );
  }
}
