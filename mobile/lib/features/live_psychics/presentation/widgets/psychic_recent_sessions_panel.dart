import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_history_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';

enum PsychicRecentSessionsMode { teller, client }

/// `GET /api/fortune-tellers/session` — falcı veya danışan oturum geçmişi.
class PsychicRecentSessionsPanel extends ConsumerWidget {
  const PsychicRecentSessionsPanel({
    super.key,
    this.title = 'Son Oturumlar',
    this.mode = PsychicRecentSessionsMode.teller,
    this.limit = 5,
  });

  final String title;
  final PsychicRecentSessionsMode mode;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(psychicRecentSessionsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFFB388FF), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          sessionsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => Column(
              children: [
                Text(
                  'Oturum geçmişi yüklenemedi.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(psychicRecentSessionsProvider),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Text(
                  mode == PsychicRecentSessionsMode.client
                      ? 'Henüz oturumunuz yok.'
                      : 'Henüz tamamlanmış oturum yok.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                );
              }
              return Column(
                children: sessions.take(limit).map((session) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SessionHistoryRow(
                      session: session,
                      mode: mode,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryRow extends StatelessWidget {
  const _SessionHistoryRow({
    required this.session,
    required this.mode,
  });

  final PsychicSessionHistoryEntity session;
  final PsychicRecentSessionsMode mode;

  @override
  Widget build(BuildContext context) {
    final label = _sessionStatusLabel(session.status);
    final color = _sessionStatusColor(session.status);
    final counterpart = mode == PsychicRecentSessionsMode.client
        ? (session.tellerName?.trim().isNotEmpty == true
            ? session.tellerName!
            : 'Falcı')
        : (session.clientName?.trim().isNotEmpty == true
            ? session.clientName!
            : (session.tellerName?.trim().isNotEmpty == true
                ? session.tellerName!
                : 'Danışan'));
    final meta = <String>[
      if (session.fortuneType.isNotEmpty) session.fortuneType,
      if (session.maxMinutes > 0) '${session.maxMinutes} dk',
      if (session.createdAt != null) _formatSessionDate(session.createdAt!),
    ].join(' · ');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                counterpart,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (meta.isNotEmpty)
                Text(
                  meta,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _formatSessionDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}';
  }

  String _sessionStatusLabel(PsychicSessionStatus status) {
    return switch (status) {
      PsychicSessionStatus.ended => 'Tamamlandı',
      PsychicSessionStatus.cancelled => 'İptal',
      PsychicSessionStatus.rejected => 'Reddedildi',
      PsychicSessionStatus.expired => 'Süresi doldu',
      PsychicSessionStatus.active => 'Aktif',
      PsychicSessionStatus.accepted => 'Kabul',
      PsychicSessionStatus.pending => 'Bekliyor',
    };
  }

  Color _sessionStatusColor(PsychicSessionStatus status) {
    return switch (status) {
      PsychicSessionStatus.ended => const Color(0xFF00E676),
      PsychicSessionStatus.cancelled => const Color(0xFFFFB74D),
      PsychicSessionStatus.rejected => const Color(0xFFFF5252),
      PsychicSessionStatus.expired => Colors.white54,
      PsychicSessionStatus.active => const Color(0xFF40C4FF),
      PsychicSessionStatus.accepted => const Color(0xFF40C4FF),
      PsychicSessionStatus.pending => Colors.white54,
    };
  }
}
