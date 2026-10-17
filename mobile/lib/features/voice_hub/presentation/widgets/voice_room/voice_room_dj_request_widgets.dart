import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chat_room_presence.dart';
import '../../../domain/entities/dj_request.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_audio_providers.dart';
import '../../providers/voice_room_dj_requests_provider.dart';

/// Sayfanın hediye penceresini verilen kullanıcı seçili açar (DJ'e hediye).
typedef DjGiftToUser = void Function(String userId);

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

Future<void> djClapRequest(
  BuildContext context,
  WidgetRef ref, {
  required String roomKey,
  required DjRequest request,
}) async {
  final err = await ref
      .read(voiceRoomDjRequestsProvider(roomKey).notifier)
      .act(request.id, 'clap');
  if (!context.mounted) return;
  _toast(context, err ?? '👏 Alkışladın!');
}

String _presenceName(ChatRoomPresence p) {
  final n = p.nickname?.trim();
  return (n != null && n.isNotEmpty) ? n : p.name;
}

/// Sayfaya bir kez eklenir (görünmez):
/// - `!istek şarkı` yazılınca istek penceresini açar (armağan, mesaj, öne geç),
/// - yeni istek gelince oda sahibine (odadaysa) ya da aktif DJ'lere
///   «Çal / Sonra / Reddet» penceresi gösterir.
class VoiceRoomDjRequestHost extends ConsumerStatefulWidget {
  const VoiceRoomDjRequestHost({
    super.key,
    required this.roomKey,
    required this.myUserId,
    this.canHandle = false,
  });

  final String roomKey;
  final String? myUserId;
  /// Sayfanın yetki bilgisi (oda sahibi / DJ). Sunucu hedef listesi boşsa ya
  /// da bu kullanıcıyı içermiyorsa ama oda sahibi odada değilse yedek olarak
  /// kullanılır.
  final bool canHandle;

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
    final target = snap.isHandler(widget.myUserId) ||
        (widget.canHandle && snap.handlerIds.isEmpty);
    if (_dialogOpen || !target) {
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

  Future<void> _compose(String song) async {
    final live = ref.read(voiceRoomLiveProvider(widget.roomKey));
    final people = [
      for (final p in live.presence)
        if (p.id.isNotEmpty && p.id != widget.myUserId) p,
    ];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15102A),
      showDragHandle: true,
      builder: (ctx) => _DjComposeSheet(
        roomKey: widget.roomKey,
        initialSong: song,
        people: people,
        baseCost: live.dj.musicRequestCost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DjRequestsSnapshot>(
      voiceRoomDjRequestsProvider(widget.roomKey),
      (_, next) => _onSnapshot(next),
    );
    ref.listen<String?>(voiceRoomDjComposeProvider(widget.roomKey), (_, song) {
      if (song == null) return;
      ref.read(voiceRoomDjComposeProvider(widget.roomKey).notifier).state = null;
      unawaited(_compose(song));
    });
    return const SizedBox.shrink();
  }
}

class _DjRequestDialog extends StatelessWidget {
  const _DjRequestDialog({required this.request});

  final DjRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1430),
      title: Text(
        r.priority ? '⚡ Öne geçen şarkı isteği' : '🎵 Şarkı isteği',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.query,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text('İsteyen: ${r.userName}',
              style: const TextStyle(color: Colors.white70)),
          if (r.giftToName != null)
            Text('🎁 Armağan: @${r.giftToName}',
                style: const TextStyle(color: Color(0xFFFFD54F))),
          if (r.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('💬 «${r.message}»',
                  style: const TextStyle(color: Colors.white)),
            ),
          const SizedBox(height: 12),
          Text(
            r.cost > 0
                ? 'Çal\'a basınca telefonundan şarkıyı seç; yayına karışır ve '
                    '${r.cost} jeton kesilir. Reddedersen ya da 5 dakika '
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

/// `!istek` penceresi: şarkı, armağan edilecek kişi, mesaj, öne geç.
class _DjComposeSheet extends ConsumerStatefulWidget {
  const _DjComposeSheet({
    required this.roomKey,
    required this.initialSong,
    required this.people,
    required this.baseCost,
  });

  final String roomKey;
  final String initialSong;
  final List<ChatRoomPresence> people;
  final int baseCost;

  @override
  ConsumerState<_DjComposeSheet> createState() => _DjComposeSheetState();
}

class _DjComposeSheetState extends ConsumerState<_DjComposeSheet> {
  late final _song = TextEditingController(text: widget.initialSong);
  final _message = TextEditingController();
  String? _giftTo;
  var _priority = false;
  var _sending = false;

  @override
  void dispose() {
    _song.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final song = _song.text.trim();
    if (song.length < 2) {
      _toast(context, 'Şarkıcı ve şarkı adını yaz.');
      return;
    }
    setState(() => _sending = true);
    final err = await ref
        .read(voiceRoomDjRequestsProvider(widget.roomKey).notifier)
        .create(
          song,
          message: _message.text,
          giftToUserId: _giftTo,
          priority: _priority,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      _toast(context, err);
      return;
    }
    Navigator.of(context).pop();
    _toast(context, '🎵 İsteğin DJ\'e gitti. Çalınmazsa jeton iade edilir.');
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final base = widget.baseCost > 0 ? widget.baseCost : 10;
    final cost = _priority ? base * 2 : base;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🎵 Şarkı iste',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _song,
              style: const TextStyle(color: Colors.white),
              decoration: _deco('Şarkıcı – şarkı', Icons.music_note_rounded),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: _giftTo,
              dropdownColor: const Color(0xFF221A3A),
              style: const TextStyle(color: Colors.white),
              decoration: _deco('Armağan et (isteğe bağlı)', Icons.card_giftcard_rounded),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Kimseye'),
                ),
                for (final p in widget.people)
                  DropdownMenuItem<String?>(
                    value: p.id,
                    child: Text('@${_presenceName(p)}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _giftTo = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _message,
              maxLength: 100,
              style: const TextStyle(color: Colors.white),
              decoration: _deco('Mesajın (isteğe bağlı)', Icons.chat_bubble_rounded),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _priority,
              onChanged: (v) => setState(() => _priority = v),
              activeThumbColor: const Color(0xFFFFC107),
              title: Text(
                '⚡ Öne geç (${base * 2} jeton)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Sıranın başına geçersin; yine DJ onaylar.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text('Gönder · $cost jeton (çalınmazsa iade)'),
            ),
          ],
        ),
      ),
    );
  }
}

String _queueLine(DjRequestsSnapshot snap) {
  if (snap.pending.isEmpty) return '';
  final parts = <String>[];
  for (var i = 0; i < snap.pending.length && i < 5; i++) {
    final r = snap.pending[i];
    parts.add('${i + 1}. ${r.priority ? '⚡' : ''}${r.query} (@${r.userName})');
  }
  return '⏭️ Sıradakiler: ${parts.join('  ·  ')}';
}

void _openRequestSheet(
  BuildContext context, {
  required String roomKey,
  required String? myUserId,
  required bool canHandle,
  DjGiftToUser? onGiftToUser,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF15102A),
    showDragHandle: true,
    builder: (ctx) => _DjRequestSheet(
      roomKey: roomKey,
      myUserId: myUserId,
      canHandle: canHandle,
      onGiftToUser: onGiftToUser,
    ),
  );
}

/// Koltuk ızgarasındaki kare «müzik koltuğu»: çalan istek (sağdan sola kayan
/// yazı) ve sıradaki istek sayısı. Dokununca istek listesi açılır.
class VoiceRoomMusicSeatCard extends ConsumerWidget {
  const VoiceRoomMusicSeatCard({
    super.key,
    required this.roomKey,
    required this.myUserId,
    required this.canHandle,
    this.onGiftToUser,
  });

  final String roomKey;
  final String? myUserId;
  /// Oda sahibi / DJ / admin (liste + çal/reddet + durdur).
  final bool canHandle;
  final DjGiftToUser? onGiftToUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(voiceRoomDjRequestsProvider(roomKey));
    final playing = snap.playing;
    final pendingCount = snap.pending.length;
    final screenW = MediaQuery.sizeOf(context).width.clamp(280.0, 900.0);
    final side = ((screenW - 12) / 4 * 0.86).clamp(70.0, 140.0);

    final line = playing != null
        ? '🎶 ${playing.query}  •  isteyen ${playing.userName}'
            '${playing.giftToName != null ? '  •  🎁 @${playing.giftToName}' : ''}'
            '${playing.handlerName != null ? '  •  DJ ${playing.handlerName}' : ''}'
        : '🎵 !istek şarkıcı şarkı yaz, DJ çalsın';

    return GestureDetector(
      onTap: () => _openRequestSheet(
        context,
        roomKey: roomKey,
        myUserId: myUserId,
        canHandle: canHandle,
        onGiftToUser: onGiftToUser,
      ),
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
                if (pendingCount > 0) _Badge(text: '$pendingCount'),
              ],
            ),
            const Spacer(),
            Text(
              playing != null
                  ? (playing.claps > 0 ? 'Çalıyor · 👏${playing.claps}' : 'Çalıyor')
                  : 'Müzik',
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
}

/// Koltuklar dolunca koltukların altında tam genişlik iki satırlık bant:
/// 1. satır DJ · çalan şarkı · isteyen · armağan; 2. satır mesaj · sıradakiler
/// · «İyi dinlemeler 🎶». Sağda alkış ve DJ'e hediye.
class VoiceRoomMusicTickerBanner extends ConsumerWidget {
  const VoiceRoomMusicTickerBanner({
    super.key,
    required this.roomKey,
    required this.myUserId,
    required this.canHandle,
    this.onGiftToUser,
  });

  final String roomKey;
  final String? myUserId;
  final bool canHandle;
  final DjGiftToUser? onGiftToUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(voiceRoomDjRequestsProvider(roomKey));
    final p = snap.playing;

    final top = p != null
        ? [
            if (p.handlerName != null) '🎧 DJ ${p.handlerName}',
            '🎶 ${p.query}',
            '🙋 isteyen @${p.userName}',
            if (p.giftToName != null) '🎁 @${p.giftToName} için',
            if (p.claps > 0) '👏 ${p.claps}',
          ].join('   •   ')
        : '🎵 Şu an istek çalmıyor — «!istek şarkıcı şarkı» yaz, DJ çalsın';
    final queue = _queueLine(snap);
    final bottom = [
      if (p?.message != null) '💬 @${p!.userName}: «${p.message}»',
      if (queue.isNotEmpty) queue,
      'İyi dinlemeler 🎶',
    ].join('   •   ');

    const style1 = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w900,
    );
    const style2 = TextStyle(
      color: Color(0xFFFFE9A8),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    return GestureDetector(
      onTap: () => _openRequestSheet(
        context,
        roomKey: roomKey,
        myUserId: myUserId,
        canHandle: canHandle,
        onGiftToUser: onGiftToUser,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: p != null
                ? const [Color(0xCC8E2DE2), Color(0xCCE5398C)]
                : const [Color(0xCC2A2140), Color(0xCC3B2C5E)],
          ),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(
              p != null ? Icons.graphic_eq_rounded : Icons.queue_music_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 18, child: _MarqueeText(text: top, style: style1)),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 16,
                    child: _MarqueeText(text: bottom, style: style2, speed: 34),
                  ),
                ],
              ),
            ),
            if (p != null) ...[
              const SizedBox(width: 4),
              _RoundAction(
                icon: '👏',
                onTap: () => unawaited(
                  djClapRequest(context, ref, roomKey: roomKey, request: p),
                ),
              ),
              if (onGiftToUser != null && p.handlerId != null)
                _RoundAction(
                  icon: '🎁',
                  onTap: () => onGiftToUser!(p.handlerId!),
                ),
            ],
            if (snap.pending.isNotEmpty) ...[
              const SizedBox(width: 4),
              _Badge(text: '${snap.pending.length}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(left: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.28),
        ),
        child: Text(icon, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// İstek sırası paneli: çalan şarkı (alkış, DJ'e hediye, durdur) ve bekleyenler
/// (öne geçenler üstte; DJ için Çal / Reddet, isteyen için İptal).
class _DjRequestSheet extends ConsumerWidget {
  const _DjRequestSheet({
    required this.roomKey,
    required this.myUserId,
    required this.canHandle,
    this.onGiftToUser,
  });

  final String roomKey;
  final String? myUserId;
  final bool canHandle;
  final DjGiftToUser? onGiftToUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(voiceRoomDjRequestsProvider(roomKey));
    final playing = snap.playing;
    final localPlaying = ref.read(voiceRoomTrtcMusicMixerProvider).localMusicActive;
    const white = TextStyle(color: Colors.white, fontWeight: FontWeight.w800);
    const dim = TextStyle(color: Colors.white60, fontSize: 12.5);

    String details(DjRequest r) => [
          'İsteyen @${r.userName}',
          if (r.giftToName != null) '🎁 @${r.giftToName}',
          if (r.message != null) '💬 «${r.message}»',
          if (r.cost > 0 && r.isPending) '${r.cost} jeton bloke',
        ].join(' · ');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '🎵 İstek sırası',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(voiceRoomDjComposeProvider(roomKey).notifier).state = '';
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Şarkı iste'),
                ),
              ],
            ),
            const Text(
              'Oda sahibi ya da DJ kendi telefonundan çalar; çalınırsa jeton '
              'kesilir, çalınmazsa iade edilir. ⚡ öne geçenler en üstte.',
              style: dim,
            ),
            const SizedBox(height: 10),
            if (playing != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0x668E2DE2), Color(0x66E5398C)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Çalıyor: ${playing.query}', style: white),
                          Text(
                            '${playing.handlerName != null ? 'DJ ${playing.handlerName} · ' : ''}'
                            '${details(playing)}'
                            '${playing.claps > 0 ? ' · 👏 ${playing.claps}' : ''}',
                            style: dim,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Alkışla',
                      icon: const Text('👏', style: TextStyle(fontSize: 20)),
                      onPressed: () => unawaited(djClapRequest(context, ref,
                          roomKey: roomKey, request: playing)),
                    ),
                    if (onGiftToUser != null && playing.handlerId != null)
                      IconButton(
                        tooltip: 'DJ\'e hediye',
                        icon: const Text('🎁', style: TextStyle(fontSize: 20)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onGiftToUser!(playing.handlerId!);
                        },
                      ),
                    if (canHandle && localPlaying)
                      IconButton(
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
                      ),
                  ],
                ),
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
                    for (var i = 0; i < snap.pending.length; i++)
                      _PendingTile(
                        index: i + 1,
                        request: snap.pending[i],
                        details: details(snap.pending[i]),
                        roomKey: roomKey,
                        canHandle: canHandle,
                        isMine: snap.pending[i].userId == myUserId,
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

class _PendingTile extends ConsumerWidget {
  const _PendingTile({
    required this.index,
    required this.request,
    required this.details,
    required this.roomKey,
    required this.canHandle,
    required this.isMine,
  });

  final int index;
  final DjRequest request;
  final String details;
  final String roomKey;
  final bool canHandle;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    Widget? trailing;
    if (canHandle) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Reddet',
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(djRejectRequest(context, ref, roomKey: roomKey, request: r));
            },
          ),
          IconButton(
            tooltip: 'Çal',
            icon: const Icon(Icons.play_circle_fill_rounded,
                color: Color(0xFF7CFFB2)),
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(djPlayRequest(context, ref, roomKey: roomKey, request: r));
            },
          ),
        ],
      );
    } else if (isMine) {
      trailing = TextButton(
        onPressed: () async {
          final err = await ref
              .read(voiceRoomDjRequestsProvider(roomKey).notifier)
              .act(r.id, 'cancel');
          if (!context.mounted) return;
          Navigator.of(context).pop();
          _toast(context, err ?? 'İstek iptal edildi, jeton iade edildi.');
        },
        child: const Text('İptal et'),
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 15,
        backgroundColor:
            r.priority ? const Color(0xFFFFC107) : Colors.white.withValues(alpha: 0.12),
        child: Text(
          r.priority ? '⚡' : '$index',
          style: TextStyle(
            color: r.priority ? Colors.black : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(r.query,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      subtitle: Text(details,
          style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
      trailing: trailing,
    );
  }
}

/// Sağdan sola sürekli kayan tek satır yazı (sığarsa sabit durur).
class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style, this.speed = 40});

  final String text;
  final TextStyle style;
  /// Piksel / saniye.
  final double speed;

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
        final ms = (travel / widget.speed * 1000).round();
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
