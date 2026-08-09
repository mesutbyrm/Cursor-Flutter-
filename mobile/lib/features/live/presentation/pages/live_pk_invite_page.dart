import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/pk_event_log.dart';

import '../../../voice_hub/domain/pk/pk_duration_options.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_duration_picker.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../providers/live_pk_streams_provider.dart';
import '../providers/pk_room_providers.dart';

/// Canlı yayın PK daveti — tek endpoint; liste SSE/socket ile yenilenir.
class LivePkInvitePage extends ConsumerStatefulWidget {
  const LivePkInvitePage({super.key, required this.session});

  final LiveBroadcastSession session;

  @override
  ConsumerState<LivePkInvitePage> createState() => _LivePkInvitePageState();
}

class _LivePkInvitePageState extends ConsumerState<LivePkInvitePage> {
  var _loading = false;
  var _inviting = false;
  var _durationSeconds = pkDefaultDurationSeconds;
  String? _error;
  Timer? _listRefresh;

  String? get _streamId => widget.session.streamId?.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(livePkStreamsProvider.notifier).refresh();
      _listRefresh = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted) {
          ref.read(livePkStreamsProvider.notifier).refresh(silent: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _listRefresh?.cancel();
    super.dispose();
  }

  Future<void> _invite(LiveStreamEntity opponent) async {
    final streamId = _streamId;
    if (streamId == null || streamId.isEmpty) {
      setState(() => _error = 'Yayın kimliği bulunamadı');
      return;
    }
    if (_inviting) return;
    _inviting = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    PkEventLog.requestStart(
      streamId: streamId,
      targetId: opponent.id,
    );
    try {
      Object? lastErr;

      // Birincil: birleşik PK API — tek istek; başarılıysa legacy'ye düşme.
      try {
        final unified = await ref.read(pkUnifiedInviteProvider).inviteStream(
              streamId: streamId,
              opponentStreamId: opponent.id,
              durationSeconds: _durationSeconds,
            );
        if (unified != null && unified.id.isNotEmpty) {
          PkEventLog.requestSuccess(matchId: unified.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${opponent.streamerName ?? opponent.title} kullanıcısına PK daveti gönderildi',
              ),
            ),
          );
          context.pop();
          return;
        }
      } catch (e) {
        lastErr = e;
      }

      // Yedek: kılavuz §9.4 video-streams PK
      try {
        final legacy =
            await ref.read(pkBattleRemoteProvider.notifier).inviteStream(
                  streamId: streamId,
                  opponentStreamId: opponent.id,
                  durationSeconds: _durationSeconds,
                );
        if (legacy != null) {
          PkEventLog.requestSuccess(battleId: legacy.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${opponent.streamerName ?? opponent.title} kullanıcısına PK daveti gönderildi',
              ),
            ),
          );
          context.pop();
          return;
        }
      } catch (e) {
        lastErr ??= e;
      }

      throw lastErr ?? Exception('PK daveti gönderilemedi');
    } catch (e) {
      PkEventLog.error('request', e);
      if (mounted) setState(() => _error = ApiException.userMessage(e));
    } finally {
      _inviting = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkAsync = ref.watch(livePkStreamsProvider);
    final myId = _streamId;
    final opponents = ref.read(livePkStreamsProvider.notifier).opponentsFor(myId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı PK Daveti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Listeyi yenile',
            onPressed: () =>
                ref.read(livePkStreamsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(livePkStreamsProvider.notifier).refresh(),
        child: pkAsync.when(
          loading: () {
            if (opponents.isNotEmpty) {
              return _buildList(opponents);
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          },
          error: (e, _) {
            if (opponents.isNotEmpty) return _buildList(opponents);
            return ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text('$e')),
                const SizedBox(height: 12),
                Center(
                  child: FilledButton(
                    onPressed: () =>
                        ref.read(livePkStreamsProvider.notifier).refresh(),
                    child: const Text('Tekrar dene'),
                  ),
                ),
              ],
            );
          },
          data: (_) {
            if (_error != null) {
              return ListView(
                children: [
                  const SizedBox(height: 24),
                  PkDurationPicker(
                    selectedSeconds: _durationSeconds,
                    onChanged: (s) => setState(() => _durationSeconds = s),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                ],
              );
            }
            // Davet gönderilirken tüm sayfayı spinner yapma — liste kalsın.
            if (opponents.isEmpty) {
              return ListView(
                children: [
                  PkDurationPicker(
                    selectedSeconds: _durationSeconds,
                    onChanged: (s) => setState(() => _durationSeconds = s),
                  ),
                  const SizedBox(height: 80),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...const [
                    Center(child: Text('PK için uygun canlı yayın yok')),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Yalnızca yayıncısı belli canlı yayınlar listelenir.\nAşağı çekerek yenileyin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ),
                  ],
                ],
              );
            }
            return Stack(
              children: [
                _buildList(opponents),
                if (_loading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<LiveStreamEntity> others) {
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
                ? canlifalImageProvider(s.thumbnailUrl!)
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
          onTap: _loading ? null : () => _invite(s),
        );
      },
    );
  }
}
