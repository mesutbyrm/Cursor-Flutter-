import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Gelen PK daveti — 15 sn geri sayım (sunucu süresi ile kısaltılır), kabul / red.
Future<bool?> showPkInviteDialog(
  BuildContext context, {
  required String challengerName,
  required String challengerImageUrl,
  Duration inviteTimeout = const Duration(seconds: 15),
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'PK daveti',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, a1, a2) => _PkInviteDialog(
      challengerName: challengerName,
      challengerImageUrl: challengerImageUrl,
      inviteTimeout: inviteTimeout,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      return Transform.scale(
        scale: Curves.easeOutBack.transform(anim.value),
        child: Opacity(opacity: anim.value, child: child),
      );
    },
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

  String _countdownLabel() {
    final s = _left.inSeconds;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.86,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1548), Color(0xFF12081F)],
            ),
            border: Border.all(color: const Color(0xFF9B4DFF).withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B4DFF).withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⚔ PK DAVETİ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF3D2560),
                backgroundImage: widget.challengerImageUrl.isNotEmpty
                    ? NetworkImage(widget.challengerImageUrl)
                    : null,
                child: widget.challengerImageUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white54, size: 36)
                    : null,
              ).animate().scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                  ),
              const SizedBox(height: 12),
              Text(
                '@${widget.challengerName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'seni PK savaşına davet ediyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _countdownLabel(),
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('REDDET'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF9B4DFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'KABUL ET',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
