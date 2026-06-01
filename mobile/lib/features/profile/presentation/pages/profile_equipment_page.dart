import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';

class ProfileEquipmentPage extends ConsumerWidget {
  const ProfileEquipmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = ref.watch(equipmentSettingsProvider);
    final notifier = ref.read(equipmentSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Ekipmanım',
          subtitle: 'Mikrofon, kamera ve yayın kalitesi',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              ProfileGlass(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Mikrofon'),
                      subtitle: const Text('Yayında ses gönder'),
                      value: eq.micEnabled,
                      onChanged: (v) => notifier.toggle('mic', v),
                    ),
                    SwitchListTile(
                      title: const Text('Kamera'),
                      subtitle: const Text('Görüntülü yayın'),
                      value: eq.cameraEnabled,
                      onChanged: (v) => notifier.toggle('camera', v),
                    ),
                    SwitchListTile(
                      title: const Text('Güzellik filtresi'),
                      value: eq.beautyFilter,
                      onChanged: (v) => notifier.toggle('beauty', v),
                    ),
                    SwitchListTile(
                      title: const Text('Gürültü engelleme'),
                      value: eq.noiseCancel,
                      onChanged: (v) => notifier.toggle('noise', v),
                    ),
                    SwitchListTile(
                      title: const Text('HD yayın'),
                      value: eq.hdStream,
                      onChanged: (v) => notifier.toggle('hd', v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ayarlar bir sonraki yayın hazırlık ekranında uygulanır.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
