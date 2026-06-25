import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/live_guest_layout.dart';
import '../../../domain/entities/live_stream_quality_preset.dart';
import '../../providers/live_broadcast_settings_provider.dart';
import '../../providers/live_stream_quality_provider.dart';

Future<void> showLiveBroadcastSettingsSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF151522),
    showDragHandle: true,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(liveBroadcastSettingsProvider);
          final notifier = ref.read(liveBroadcastSettingsProvider.notifier);
          final quality = ref.watch(liveStreamQualityProvider);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    title: Text(
                      'Yayın Ayarları',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text('Web ile senkron moderasyon ve etkileşim'),
                  ),
                  SwitchListTile(
                    title: const Text('Yorumlar'),
                    value: settings.commentsEnabled,
                    onChanged: notifier.toggleComments,
                  ),
                  SwitchListTile(
                    title: const Text('Hediyeler'),
                    value: settings.giftsEnabled,
                    onChanged: notifier.toggleGifts,
                  ),
                  SwitchListTile(
                    title: const Text('PK Battle'),
                    value: settings.pkEnabled,
                    onChanged: notifier.togglePk,
                  ),
                  SwitchListTile(
                    title: const Text('Konuk alma'),
                    value: settings.guestsEnabled,
                    onChanged: notifier.toggleGuests,
                  ),
                  SwitchListTile(
                    title: const Text('Çoklu yayın'),
                    value: settings.coBroadcastEnabled,
                    onChanged: notifier.toggleCoBroadcast,
                  ),
                  if (settings.coBroadcastEnabled) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Grid kapasitesi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: LiveGuestLayout.values.map((g) {
                        final selected = settings.guestLayout == g;
                        return ChoiceChip(
                          label: Text(g.label),
                          selected: selected,
                          onSelected: (_) => notifier.setGuestLayout(g),
                        );
                      }).toList(),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Video kalitesi (düşük gecikme)',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: LiveStreamQualityPreset.values.map((q) {
                      return ChoiceChip(
                        label: Text(q.label),
                        selected: quality == q,
                        onSelected: (_) => ref
                            .read(liveStreamQualityProvider.notifier)
                            .setPreset(q),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
