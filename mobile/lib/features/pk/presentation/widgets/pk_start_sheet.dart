import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../voice_hub/domain/pk/pk_duration_options.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_duration_picker.dart';
import '../../data/pk_models.dart';
import '../providers/pk_feature_enabled_provider.dart';
import '../providers/pk_session_notifier.dart';

/// Sesli oda PK — birleşik aday listesi (`/api/chat/rooms/pk/candidates`).
Future<void> openVoicePkInviteSheet(
  BuildContext context,
  WidgetRef ref,
  VoiceRoomEntity room,
) async {
  if (!ref.read(pkFeatureEnabledProvider)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PK özelliği şu an kapalı')),
    );
    return;
  }
  final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  if (key.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Oda bilgisi yüklenemedi — PK başlatılamadı')),
    );
    return;
  }
  await showPkStartSheet(
    context,
    ref,
    args: PkSessionArgs(contextId: key, kind: PkContextKind.voice),
  );
}

/// PK gönder — aday listesi + süre seçici (premium).
Future<void> showPkStartSheet(
  BuildContext context,
  WidgetRef ref, {
  required PkSessionArgs args,
}) async {
  if (!ref.read(pkFeatureEnabledProvider)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PK özelliği şu an kapalı')),
    );
    return;
  }
  await ref.read(pkSessionProvider(args).notifier).loadCandidates();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12081F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _PkStartSheet(args: args),
  );
}

class _PkStartSheet extends ConsumerStatefulWidget {
  const _PkStartSheet({required this.args});

  final PkSessionArgs args;

  @override
  ConsumerState<_PkStartSheet> createState() => _PkStartSheetState();
}

class _PkStartSheetState extends ConsumerState<_PkStartSheet> {
  var _duration = pkDefaultDurationSeconds;
  String? _invitingTargetId;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pkSessionProvider(widget.args));
    final bottom = MediaQuery.paddingOf(context).bottom;
    final busy = session.selfBusy ||
        session.isRateLimited ||
        session.loading ||
        _invitingTargetId != null;
    final pending = session.battle?.status == PkStatus.pending;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  '⚔️',
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'PK SAVAŞI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (session.loading &&
                    session.candidates.isEmpty &&
                    session.battle == null)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.args.kind == PkContextKind.live
                  ? 'Karşı yayıncı seç'
                  : 'Aktif sesli odalardan birini seç',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            if (pending && session.battle != null) ...[
              const SizedBox(height: 14),
              _PendingInvitePanel(
                args: widget.args,
                battle: session.battle!,
                inviteRemaining: session.inviteRemaining,
              ),
              const SizedBox(height: 8),
              Text(
                'Karşı taraf kabul ettiğinde PK başlayacaktır.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              PkDurationPicker(
                selectedSeconds: _duration,
                onChanged: busy ? (_) {} : (v) => setState(() => _duration = v),
              ),
              const SizedBox(height: 12),
            ],
            if (session.isRateLimited)
              _banner(
                'Çok fazla istek — lütfen biraz bekleyin',
                Colors.orangeAccent,
              ),
            if (session.error != null)
              _banner(session.error!, Colors.orangeAccent),
            if (pending && session.battle != null)
              const SizedBox.shrink()
            else if (session.candidates.isEmpty && !session.loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(
                      Icons.live_tv_rounded,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Şu an PK yapılabilecek aktif oda yok.\n'
                      'Rakip oda sahibinin son 2 dakikada odada olması gerekir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: busy
                          ? null
                          : () => ref
                              .read(pkSessionProvider(widget.args).notifier)
                              .loadCandidates(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Yenile'),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.48,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: session.candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = session.candidates[index];
                    final inviting = _invitingTargetId == c.contextId;
                    return _CandidateTile(
                      candidate: c,
                      inviting: inviting,
                      onInvite: busy ? null : () => _invite(c),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _banner(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _invite(PkCandidate c) async {
    setState(() => _invitingTargetId = c.contextId);
    await ref
        .read(pkSessionProvider(widget.args).notifier)
        .create(c.contextId, durationSeconds: _duration, targetUserId: c.userId);
    if (!mounted) return;
    setState(() => _invitingTargetId = null);
    final err = ref.read(pkSessionProvider(widget.args)).error;
    if (err == null) {
      final stillPending =
          ref.read(pkSessionProvider(widget.args)).battle?.status ==
              PkStatus.pending;
      if (!stillPending && mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class _PendingInvitePanel extends ConsumerWidget {
  const _PendingInvitePanel({
    required this.args,
    required this.battle,
    this.inviteRemaining,
  });

  final PkSessionArgs args;
  final PkBattle battle;
  final Duration? inviteRemaining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sec = (inviteRemaining ?? const Duration(seconds: 60)).inSeconds
        .clamp(0, 99);
    final m = sec ~/ 60;
    final r = sec % 60;
    final label =
        '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
    final name = battle.user2?.name ?? battle.user1?.name ?? 'Yayıncı';
    final image = battle.user2?.image ?? battle.user1?.image ?? '';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF2A1540).withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFF9B4DFF).withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      image.isNotEmpty ? NetworkImage(image) : null,
                  child: image.isEmpty
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        '🟢 CANLI',
                        style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'PK İSTEĞİ GÖNDERİLDİ',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await ref.read(pkSessionProvider(args).notifier).cancel();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.onInvite,
    this.inviting = false,
  });

  final PkCandidate candidate;
  final VoidCallback? onInvite;
  final bool inviting;

  @override
  Widget build(BuildContext context) {
    final name =
        candidate.name.isNotEmpty ? candidate.name : 'Yayıncı';
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A1540).withValues(alpha: 0.95),
            const Color(0xFF1A0F2E),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF3D2560),
                  backgroundImage: candidate.image.isNotEmpty
                      ? NetworkImage(candidate.image)
                      : null,
                  child: candidate.image.isEmpty
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D7A),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2D7A).withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      'CANLI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (candidate.title.isNotEmpty)
                    Text(
                      candidate.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  if (candidate.viewers > 0)
                    Text(
                      '${candidate.viewers} izleyici',
                      style: const TextStyle(
                        color: Color(0xFFB794F6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onInvite,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9B4DFF),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 40),
              ),
              child: inviting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'PK İSTEĞİ GÖNDER',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
