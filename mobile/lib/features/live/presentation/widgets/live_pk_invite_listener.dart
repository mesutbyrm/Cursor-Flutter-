import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/pk/live_pk_invite_helper.dart';
import '../../domain/pk/pk_unified_bridge.dart';
import '../providers/pk_room_providers.dart';

/// Uygulama genelinde bekleyen PK davetlerini dinler — yayıncı odada olmasa bile popup.
class LivePkInviteListener extends ConsumerStatefulWidget {
  const LivePkInviteListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LivePkInviteListener> createState() =>
      _LivePkInviteListenerState();
}

class _LivePkInviteListenerState extends ConsumerState<LivePkInviteListener> {
  Timer? _timer;
  final Set<String> _seen = {};
  var _showing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
    Future.microtask(_poll);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_showing || !mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    try {
      final invites = await ref.read(pkPendingInvitesProvider.future);
      for (final inv in invites) {
        if (!inv.isPending) continue;
        if (!isLivePkInviteRecipient(
          inv,
          myStreamId: '',
          myUserId: user.id,
        )) {
          continue;
        }
        if (!_seen.add(inv.id)) continue;
        await _showDialog(inv);
        break;
      }
    } catch (_) {}
  }

  Future<void> _showDialog(inv) async {
    if (!mounted || _showing) return;
    _showing = true;
    final battle = pkRoomMatchToBattleMap(inv);
    final challenger = battle['leftName']?.toString() ?? 'Yayıncı';
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F2E),
        title: const Text('PK Daveti', style: TextStyle(color: Colors.white)),
        content: Text(
          '$challenger size PK daveti gönderdi.\nKabul ediyor musunuz?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Reddet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kabul Et'),
          ),
        ],
      ),
    );
    _showing = false;
    if (!mounted || accept == null) return;
    try {
      await ref.read(pkUnifiedInviteProvider).respond(
            matchId: inv.id,
            accept: accept,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'PK kabul edildi — yayın odanıza dönün' : 'PK reddedildi',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
