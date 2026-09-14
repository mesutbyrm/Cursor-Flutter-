import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/pk_models.dart';
import '../providers/pk_providers.dart';
import '../providers/pk_session_notifier.dart';

/// Gelen PK daveti — 60 sn geri sayım, kabul / red.
Future<bool?> showPkInviteDialog(
  BuildContext context, {
  required String challengerName,
  required String challengerImageUrl,
  Duration inviteTimeout = const Duration(seconds: 60),
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => _PkInviteDialog(
      challengerName: challengerName,
      challengerImageUrl: challengerImageUrl,
      inviteTimeout: inviteTimeout,
    ),
  );
}

class _PkInviteDialog extends StatefulWidget {
  const _PkInviteDialog({
    required this.challengerName,
    required this.challengerImageUrl,
    required this.inviteTimeout,
  });

  final String challengerName;
  final String challengerImageUrl;
  final Duration inviteTimeout;

  @override
  State<_PkInviteDialog> createState() => _PkInviteDialogState();
}

class _PkInviteDialogState extends State<_PkInviteDialog> {
  late Duration _left;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _left = widget.inviteTimeout;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _left = Duration(seconds: (_left.inSeconds - 1).clamp(0, 999));
      });
      if (_left.inSeconds <= 0) {
        Navigator.pop(context, null);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sec = _left.inSeconds;
    return AlertDialog(
      backgroundColor: const Color(0xFF1A0F2E),
      title: const Row(
        children: [
          Text('🔥 ', style: TextStyle(fontSize: 22)),
          Text('PK Daveti', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: widget.challengerImageUrl.isNotEmpty
                ? NetworkImage(widget.challengerImageUrl)
                : null,
            child: widget.challengerImageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white54)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.challengerName} PK daveti gönderdi',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Text(
            '${sec}s',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Reddet'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Kabul Et'),
        ),
      ],
    );
  }
}

/// Oturum + diyalog — kabul/red sonrası birleşik API.
Future<void> runPkInviteDialogForSession(
  BuildContext context,
  WidgetRef ref,
  PkSessionArgs args, {
  required PkBattle battle,
  required String challengerName,
  String challengerImageUrl = '',
}) async {
  final accept = await showPkInviteDialog(
    context,
    challengerName: challengerName,
    challengerImageUrl: challengerImageUrl,
    inviteTimeout: battle.remainingInvite(ref.read(pkServiceProvider).clockSkew) ??
        const Duration(seconds: 60),
  );
  if (!context.mounted || accept == null) return;
  final notifier = ref.read(pkSessionProvider(args).notifier);
  if (accept) {
    await notifier.accept();
  } else {
    await notifier.reject();
  }
}
