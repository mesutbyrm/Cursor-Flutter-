import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shorts_playback_providers.dart';

Future<void> showShortsSafeSettingsSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF121218),
    builder: (ctx) => const _ShortsSafeSettingsSheet(),
  );
}

class _ShortsSafeSettingsSheet extends ConsumerWidget {
  const _ShortsSafeSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(shortsSafeSettingsProvider);
    return SafeArea(
      child: settings.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Ayarlar yüklenemedi.'),
        ),
        data: (s) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Çocuk güvenliği ve filtre',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Kısa video akışı tercihleri'),
            ),
            SwitchListTile(
              title: const Text('Kısıtlı mod'),
              subtitle: const Text(
                'Hassas içerikleri gizler; yalnızca genel içerik gösterilir.',
              ),
              value: s.restrictedMode,
              onChanged: (v) => ref
                  .read(shortsSafeSettingsProvider.notifier)
                  .setRestrictedMode(v),
            ),
            SwitchListTile(
              title: const Text('Yetişkin içeriği gizle'),
              subtitle: const Text('Mature etiketli videolar akışta gösterilmez.'),
              value: s.hideMature,
              onChanged: (v) => ref
                  .read(shortsSafeSettingsProvider.notifier)
                  .setHideMature(v),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
