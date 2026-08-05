import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../diagnostics/psychic_rtc_session_report.dart';

/// Falcı TRTC oturum günlüğü — panelde genişletilebilir kart.
class PsychicRtcSessionReportCard extends StatefulWidget {
  const PsychicRtcSessionReportCard({super.key});

  @override
  State<PsychicRtcSessionReportCard> createState() =>
      _PsychicRtcSessionReportCardState();
}

class _PsychicRtcSessionReportCardState extends State<PsychicRtcSessionReportCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final events = PsychicRtcSessionReport.snapshot();
    if (events.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.videocam_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'RTC oturum günlüğü boş — 1:1 görüşme sonrası burada görünür',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text(
              'RTC oturum günlüğü',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            subtitle: Text('${events.length} olay'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Temizle',
                  onPressed: () {
                    PsychicRtcSessionReport.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in events.reversed.take(12))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${e['ts']} · ${e['phase']}',
                        style: const TextStyle(fontSize: 10, height: 1.3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
