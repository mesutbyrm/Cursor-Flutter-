import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/dj_request.dart';
import '../../providers/voice_room_audio_providers.dart';
import '../../providers/voice_room_dj_requests_provider.dart';

void _toast(BuildContext context, String message) {
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(SnackBar(content: Text(message)));
}

/// DJ: telefondan müzik dosyası seçer, yayına karıştırır ve isteği «çalıyor»
/// yapar (jeton bu anda kesilir). Dosya seçilmezse istek beklemede kalır.
Future<void> djPlayRequest(
  BuildContext context,
  WidgetRef ref, {
  required String roomKey,
  required DjRequest request,
}) async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.audio,
    allowMultiple: false,
  );
  final path = picked?.files.single.path;
  if (path == null || path.isEmpty) return;
  if (!context.mounted) return;

  final ctrl = ref.read(voiceRoomDjRequestsProvider(roomKey).notifier);
  final mixer = ref.read(voiceRoomTrtcMusicMixerProvider);
  final err = await mixer.playLocalFile(
    path,
    onFinished: () => unawaited(ctrl.act(request.id, 'done')),
    onError: (m) {
      unawaited(ctrl.act(request.id, 'done'));
      if (context.mounted) _toast(context, m);
    },
  );
  if (err != null) {
    if (context.mounted) _toast(context, err);
    return;
  }
  final actErr = await ctrl.act(request.id, 'play');
  if (actErr != null) {
    mixer.stopLocalFile();
    if (context.mounted) _toast(context, actErr);
    return;
  }
  if (context.mounted) _toast(context, '🎶 Yayında: ${request.query}');
}

Future<void> djRejectRequest(
  BuildContext context,
  WidgetRef ref, {
  required String roomKey,
  required DjRequest request,
}) async {
  final err = await ref
      .read(voiceRoomDjRequestsProvider(roomKey).notifier)
      .act(request.id, 'reject');
  if (!context.mounted) return;
  _toast(context, err ?? 'İstek reddedildi, jeton iade edildi.');
}

/// Yeni istek gelince oda sahibine (odadaysa) ya da aktif DJ'lere açılır
/// pencere gösterir. Ekranda görünmez; sayfa ağacına bir kez eklenir.
class VoiceRoomDjRequestHost extends ConsumerStatefulWidget {
  const VoiceRoomDjRequestHost({
    super.key,
    required this.roomKey,
    required this.myUserId,
  });

  final String roomKey;
  final String? myUserId;

  @override
  ConsumerState<VoiceRoomDjRequestHost> createState() =>
      _VoiceRoomDjRequestHostState();
}

class _VoiceRoomDjRequestHostState
    extends ConsumerState<VoiceRoomDjRequestHost> {
  final _seen = <String>{};
  var _dialogOpen = false;
  var _primed = false;

  void _onSnapshot(DjRequestsSnapshot snap) {
    if (!snap.loaded) return;
    // İlk yüklemede eski istekler için pencere açılmaz (kart üzerinden görülür).
    if (!_primed) {
      _primed = true;
      _seen.addAll(snap.pending.map((e) => e.id));
      return;
    }
    if (_dialogOpen || !snap.isHandler(widget.myUserId)) {
      _seen.addAll(snap.pending.map((e) => e.id));
      return;
    }
    DjRequest? fresh;
    for (final r in snap.pending) {
      if (_seen.add(r.id) && fresh == null) fresh = r;
    }
    if (fresh != null) unawaited(_show(fresh));
  }

  Future<void> _show(DjRequest r) async {
    _dialogOpen = true;
    try {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => _DjRequestDialog(request: r),
      );
      if (!mounted) return;
      if (choice == 'play') {
        await djPlayRequest(context, ref, roomKey: widget.roomKey, request: r);
      } else if (choice == 'reject') {
        await djRejectRequest(context, ref, roomKey: widget.roomKey, request: r);
      }
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DjRequestsSnapshot>(
      voiceRoomDjRequestsProvider(widget.roomKey),
      (_, next) => _onSnapshot(next),
    );
    return const SizedBox.shrink();
  }
}

class _DjRequestDialog extends StatelessWidget {
  const _DjRequestDialog({required this.request});

  final DjRequest request;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1430),
      title: const Text(
        '🎵 Şarkı isteği',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.query,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'İsteyen: ${request.userName}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            request.cost > 0
                ? 'Çal\'a basınca telefonundan şarkıyı seç; yayına karışır ve '
                    '${request.cost} jeton kesilir. Reddedersen ya da 5 dakika '
                    'içinde çalmazsan jeton iade edilir.'
                : 'Çal\'a basınca telefonundan şarkıyı seç; yayına karışır.',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('reject'),
          child: const Text('Reddet', style: TextStyle(color: Colors.redAccent)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Sonra', style: TextStyle(color: Colors.white70)),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop('play'),
          icon: const Icon(Icons.library_music_rounded),
          label: const Text('Çal'),
        ),
      ],
    );
  }
}

/// Koltuk ızgarasındaki kare «müzik koltuğu»: çalan istek (sağdan sola kayan
/// yazı) ve sıradaki istek sayısı. DJ dokununca istek listesi açılır.
class VoiceRoomMusicSeatCard extends ConsumerWidget {
  const VoiceRoomMusicSeatCard({
    super.key,
    required this.roomKey,
    required this.myUserId,
    required this.canHandle,
  });

  final String roomKey;
  final String? myUserId;
  /// Oda sahibi / DJ / admin (liste + çal/reddet + durdur).
  final bool canHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(voiceRoomDjRequestsProvider(roomKey));
    final playing = snap.playing;
    final pendingCount = snap.pending.length;
    final screenW = MediaQuery.sizeOf(context).width.clamp(280.0, 900.0);
    final side = ((screenW - 12) / 4 * 0.86).clamp(70.0, 140.0);

    final line = playing != null
        ? '🎶 ${playing.query}  •  isteyen ${playing.userName}'
            '${playing.handlerName != null ? '  •  DJ ${playing.handlerName}' : ''}'
        : '🎵 !istek şarkıcı şarkı yaz, DJ çalsın';

    return GestureDetector(
      onTap: () => _openSheet(context, ref),
      child: Container(
        width: side,
        height: side,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: playing != null
                ? const [Color(0xFF8E2DE2), Color(0xFFE5398C)]
                : const [Color(0xFF2A2140), Color(0xFF3B2C5E)],
          ),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            if (playing != null)
              const BoxShadow(color: Color(0x668E2DE2), blurRadius: 14),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  playing != null
                      ? Icons.graphic_eq_rounded
                      : Icons.queue_music_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const Spacer(),
                if (pendingCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              playing != null ? 'Çalıyor' : 'Müzik',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 18,
              child: _MarqueeText(
                text: line,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF15102A),
      showDragHandle: true,
      builder: (ctx) => _DjRequestSheet(
        roomKey: roomKey,
        myUserId: myUserId,
        canHandle: canHandle,
      ),
    );
  }
}

class _DjRequestSheet extends ConsumerWidget {
  const _DjRequestSheet({
    required this.roomKey,
    required this.myUserId,
    required this.canHandle,
  });

  final String roomKey;
  final String? myUserId;
  final bool canHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(voiceRoomDjRequestsProvider(roomKey));
    final playing = snap.playing;
    final localPlaying = ref.read(voiceRoomTrtcMusicMixerProvider).localMusicActive;
    const white = TextStyle(color: Colors.white, fontWeight: FontWeight.w800);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎵 Müzik istekleri',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text(
              'Sohbete «!istek şarkıcı şarkı» yaz. Oda sahibi ya da DJ '
              'kendi telefonundan çalar; çalınırsa jeton kesilir, çalınmazsa '
              'iade edilir.',
              style: TextStyle(color: Colors.white60, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            if (playing != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.graphic_eq_rounded,
                    color: Color(0xFFE5398C)),
                title: Text(playing.query, style: white),
                subtitle: Text('İsteyen ${playing.userName}',
                    style: const TextStyle(color: Colors.white60)),
                trailing: canHandle && localPlaying
                    ? IconButton(
                        tooltip: 'Durdur',
                        icon: const Icon(Icons.stop_circle_rounded,
                            color: Colors.white),
                        onPressed: () {
                          ref.read(voiceRoomTrtcMusicMixerProvider).stopLocalFile();
                          unawaited(ref
                              .read(voiceRoomDjRequestsProvider(roomKey).notifier)
                              .act(playing.id, 'done'));
                          Navigator.of(context).pop();
                        },
                      )
                    : null,
              ),
            if (snap.pending.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Bekleyen istek yok.',
                    style: TextStyle(color: Colors.white54)),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in snap.pending)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.music_note_rounded,
                            color: Colors.white70),
                        title: Text(r.query, style: white),
                        subtitle: Text(
                          'İsteyen ${r.userName}'
                          '${r.cost > 0 ? ' · ${r.cost} jeton bloke' : ''}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: canHandle
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Reddet',
                                    icon: const Icon(Icons.close_rounded,
                                        color: Colors.redAccent),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      unawaited(djRejectRequest(context, ref,
                                          roomKey: roomKey, request: r));
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Çal',
                                    icon: const Icon(Icons.play_circle_fill_rounded,
                                        color: Color(0xFF7CFFB2)),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      unawaited(djPlayRequest(context, ref,
                                          roomKey: roomKey, request: r));
                                    },
                                  ),
                                ],
                              )
                            : r.userId == myUserId
                                ? TextButton(
                                    onPressed: () async {
                                      final err = await ref
                                          .read(voiceRoomDjRequestsProvider(roomKey)
                                              .notifier)
                                          .act(r.id, 'cancel');
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop();
                                      _toast(context,
                                          err ?? 'İstek iptal edildi, jeton iade edildi.');
                                    },
                                    child: const Text('İptal et'),
                                  )
                                : null,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sağdan sola sürekli kayan tek satır yazı (sığarsa sabit durur).
class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        final textW = tp.width;
        final boxW = box.maxWidth;
        if (textW <= boxW) {
          if (_ctrl.isAnimating) _ctrl.stop();
          return Center(
            child: Text(widget.text, maxLines: 1, style: widget.style),
          );
        }
        final travel = boxW + textW;
        final ms = (travel / 40 * 1000).round();
        if (_ctrl.duration?.inMilliseconds != ms || !_ctrl.isAnimating) {
          _ctrl.duration = Duration(milliseconds: ms);
          _ctrl.repeat();
        }
        return ClipRect(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Transform.translate(
              offset: Offset(boxW - travel * _ctrl.value, 0),
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: Text(widget.text, maxLines: 1, style: widget.style),
              ),
            ),
          ),
        );
      },
    );
  }
}
