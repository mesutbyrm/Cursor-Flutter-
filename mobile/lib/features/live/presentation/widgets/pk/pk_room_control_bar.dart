import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../domain/pk/pk_event_models.dart';
import '../../../domain/pk/pk_room_models.dart';
import '../../providers/pk_room_providers.dart';

/// PK Faz 2 kontrol çubuğu — role/duruma göre buton seti.
/// Host: Başlat / Bitir / (koltuk kick sheet). İzleyici: Katıl (takım seç) / Bırak.
class PkRoomControlBar extends ConsumerStatefulWidget {
  const PkRoomControlBar({
    super.key,
    required this.matchId,
    required this.myUserId,
    this.myStreamId,
  });

  final String matchId;
  final String myUserId;
  final String? myStreamId;

  @override
  ConsumerState<PkRoomControlBar> createState() => _PkRoomControlBarState();
}

class _PkRoomControlBarState extends ConsumerState<PkRoomControlBar> {
  bool _busy = false;

  Future<void> _run(Future<PkRoomMatch?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final m = await action();
      if (m != null) {
        ref.read(pkRoomProvider(widget.matchId).notifier).adopt(m);
      } else {
        await ref.read(pkRoomProvider(widget.matchId).notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isMine(PkSeat s) => s.userId == widget.myUserId;

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(pkRoomProvider(widget.matchId));
    if (match == null || match.mode == PkRoomMode.oneVsOne) {
      return const SizedBox.shrink();
    }
    final isHost = match.hostUserId == widget.myUserId;
    final mySeat = match.seats.where((s) => _isMine(s) && s.isOccupied).isNotEmpty
        ? match.activeSeats.firstWhere(_isMine)
        : null;

    final buttons = <Widget>[];

    if (isHost && match.isPending) {
      buttons.add(_btn('Başlat', Icons.play_arrow_rounded, const Color(0xFF66E36F),
          () => _run(() => ref.read(pkRoomRemoteProvider).start(widget.matchId))));
    }
    if (isHost && match.isLive) {
      buttons.add(_btn('Bitir', Icons.stop_rounded, const Color(0xFFFF6E6E),
          () => _run(() => ref.read(pkRoomRemoteProvider).end(widget.matchId))));
      buttons.add(_btn('Koltukları Yönet', Icons.manage_accounts_rounded,
          const Color(0xFF7C3AED), () => _openManage(match)));
      buttons.add(_btn('Etkinlik', Icons.auto_awesome_rounded,
          const Color(0xFFFFD54F), _openEvents));
    }
    if (!isHost) {
      if (mySeat == null && !match.isCompleted) {
        buttons.add(_btn('Katıl', Icons.event_seat_rounded, const Color(0xFF3D7BFF),
            () => _join(match)));
      } else if (mySeat != null) {
        buttons.add(_btn('Koltuğu Bırak', Icons.logout_rounded,
            const Color(0xFFFF8A65),
            () => _run(() => ref.read(pkRoomRemoteProvider).leaveSeat(widget.matchId))));
      }
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
    return FilledButton.icon(
      onPressed: _busy ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Future<void> _join(PkRoomMatch match) async {
    String? team;
    if (match.isTeam) {
      team = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF12082A),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Takım seç',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
              ),
              ListTile(
                leading: const Icon(Icons.circle, color: Color(0xFFFF3D77)),
                title: Text(match.leftName,
                    style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, 'left'),
              ),
              ListTile(
                leading: const Icon(Icons.circle, color: Color(0xFF3D7BFF)),
                title: Text(match.rightName,
                    style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, 'right'),
              ),
            ],
          ),
        ),
      );
      if (team == null) return;
    }
    await _run(() => ref.read(pkRoomRemoteProvider).joinSeat(
          widget.matchId,
          team: team,
          streamId: widget.myStreamId,
        ));
  }

  Future<void> _openEvents() async {
    final type = await showModalBottomSheet<PkEventType>(
      context: context,
      backgroundColor: const Color(0xFF12082A),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Premium Etkinlik Başlat',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ),
            for (final t in PkEventType.values)
              ListTile(
                leading: Text(t.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(t.label,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  switch (t) {
                    PkEventType.luckyGift => 'x2 · 30 sn',
                    PkEventType.goldenMinute => 'x3 · 60 sn',
                    PkEventType.doubleScore => 'x2 · 60 sn',
                    PkEventType.finalFrenzy => 'x5 · 30 sn',
                  },
                  style: TextStyle(color: t.color, fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (type == null) return;
    try {
      final event =
          await ref.read(pkRoomRemoteProvider).triggerEvent(widget.matchId, type: type);
      if (event != null) {
        ref.read(pkActiveEventProvider(widget.matchId).notifier).adopt(event);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type.label} başladı!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  Future<void> _openManage(PkRoomMatch match) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12082A),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Koltuktaki kullanıcılar',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ),
            for (final s in match.activeSeats.where((s) => !s.isHost))
              ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: s.isLeft
                      ? const Color(0xFFFF3D77)
                      : (s.isRight ? const Color(0xFF3D7BFF) : const Color(0xFF6C3FC5)),
                  child: Text('${s.seatIndex}',
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                title: Text(s.displayName ?? 'Koltuk ${s.seatIndex}',
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text('${s.score} puan',
                    style: const TextStyle(color: Color(0x99FFFFFF))),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.person_remove_rounded,
                      color: Color(0xFFFF6E6E), size: 18),
                  label: const Text('Çıkar',
                      style: TextStyle(color: Color(0xFFFF6E6E))),
                  onPressed: s.userId == null
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _run(() => ref
                              .read(pkRoomRemoteProvider)
                              .kickSeat(widget.matchId, userId: s.userId!));
                        },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
