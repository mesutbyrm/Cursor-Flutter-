import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../vip_gold/domain/entrance_theme.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/entrance_effect_settings_provider.dart';
import '../../../vip_gold/presentation/widgets/vip_entrance_overlay.dart';
import '../providers/staff_access_provider.dart';

/// Admin — giriş efekti hızı, süre ve üyelik kademesi ayarları.
class AdminEntranceEffectsPage extends ConsumerStatefulWidget {
  const AdminEntranceEffectsPage({super.key});

  @override
  ConsumerState<AdminEntranceEffectsPage> createState() =>
      _AdminEntranceEffectsPageState();
}

class _AdminEntranceEffectsPageState
    extends ConsumerState<AdminEntranceEffectsPage> {
  var _preview = false;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageGifts) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Giriş efekti ayarları yalnızca admin içindir.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final settings = ref.watch(entranceEffectSettingsProvider);
    final notifier = ref.read(entranceEffectSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top + 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 12),
                  child: Row(
                    children: [
                      DiscoverIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Expanded(
                        child: DiscoverTabHeader(
                          title: 'Giriş efektleri',
                          subtitle: 'Hız, süre, Gold/Diamond/SVIP',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      _SliderTile(
                        label: 'Hız',
                        value: settings.speed,
                        min: 0.6,
                        max: 2.0,
                        divisions: 14,
                        display: '${settings.speed.toStringAsFixed(1)}×',
                        onChanged: (v) => notifier.update(
                          settings.copyWith(speed: v),
                        ),
                      ),
                      _SliderTile(
                        label: 'Süre (ms)',
                        value: settings.durationMs.toDouble(),
                        min: 1400,
                        max: 4200,
                        divisions: 14,
                        display: '${settings.durationMs} ms',
                        onChanged: (v) => notifier.update(
                          settings.copyWith(durationMs: v.round()),
                        ),
                      ),
                      _SliderTile(
                        label: 'Geçiş sayısı',
                        value: settings.passCount.toDouble(),
                        min: 1,
                        max: 3,
                        divisions: 2,
                        display: '${settings.passCount}',
                        onChanged: (v) => notifier.update(
                          settings.copyWith(passCount: v.round()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Gold giriş efekti'),
                        value: settings.goldEnabled,
                        onChanged: (v) =>
                            notifier.update(settings.copyWith(goldEnabled: v)),
                      ),
                      SwitchListTile(
                        title: const Text('Diamond giriş efekti'),
                        value: settings.diamondEnabled,
                        onChanged: (v) => notifier.update(
                          settings.copyWith(diamondEnabled: v),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('SVIP giriş efekti'),
                        value: settings.svipEnabled,
                        onChanged: (v) =>
                            notifier.update(settings.copyWith(svipEnabled: v)),
                      ),
                      SwitchListTile(
                        title: const Text('Admin / yetkili giriş'),
                        value: settings.adminEnabled,
                        onChanged: (v) => notifier.update(
                          settings.copyWith(adminEnabled: v),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Takım renkleri'),
                        subtitle: const Text(
                          'Kullanıcının seçtiği takım/şehir renkleri',
                        ),
                        value: settings.teamColorsEnabled,
                        onChanged: (v) => notifier.update(
                          settings.copyWith(teamColorsEnabled: v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => setState(() => _preview = true),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Önizleme oynat'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppThemeColors.accentPink,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Takım kataloğu: ${TeamCatalog.options.length} kulüp, '
                        '${CityCatalog.options.length} şehir',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_preview)
              VipEntranceOverlay(
                tier: VipTier.gold,
                theme: TeamCatalog.resolve(favoriteTeam: 'galatasaray'),
                userName: access.username ?? 'Admin',
                onFinished: () {
                  if (mounted) setState(() => _preview = false);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Text(display, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
