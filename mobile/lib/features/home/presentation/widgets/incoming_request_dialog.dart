import 'package:flutter/material.dart';

import '../../domain/entities/live_fortune_session_entity.dart';
import '../widgets/live_fortune_fortune_type_chip.dart';

/// Bekleyen canlı fal isteği — Kabul Et / Reddet.
class IncomingRequestDialog extends StatelessWidget {
  const IncomingRequestDialog({
    super.key,
    required this.session,
    required this.onAccept,
    required this.onReject,
    this.busy = false,
  });

  final FortuneIncomingSession session;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool busy;

  static Future<void> show(
    BuildContext context, {
    required FortuneIncomingSession session,
    required Future<void> Function() onAccept,
    required Future<void> Function() onReject,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var loading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return IncomingRequestDialog(
              session: session,
              busy: loading,
              onAccept: () async {
                if (loading) return;
                setState(() => loading = true);
                await onAccept();
                if (context.mounted) Navigator.of(context).pop();
              },
              onReject: () async {
                if (loading) return;
                setState(() => loading = true);
                await onReject();
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A0F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Yeni Fal Talebi',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.clientName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            fortuneTypeLabel(session.category),
            style: const TextStyle(color: Color(0xFFB794F6), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _row(Icons.schedule, 'Süre', '${session.durationMinutes} dakika'),
          const SizedBox(height: 8),
          _row(Icons.monetization_on_outlined, 'Jeton', '${session.totalJeton}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : onReject,
          child: const Text('Reddet', style: TextStyle(color: Colors.redAccent)),
        ),
        FilledButton(
          onPressed: busy ? null : onAccept,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kabul Et'),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
