import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/settings_kit.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../domain/entrance_visual_style.dart';
import '../providers/entrance_effect_settings_provider.dart';
import '../../../../core/membership/membership_capability_keys.dart';
import '../../../../core/membership/membership_capability_providers.dart';
import '../providers/vip_membership_provider.dart';
import '../widgets/gold_team_top_entrance_banner.dart';
import '../../domain/entrance_theme.dart';
import '../providers/user_room_profile_provider.dart';

/// Gold+ kullanıcı — giriş efekti hızı, takım renkleri, üstten geçiş.
class EntranceEffectUserSettingsPage extends ConsumerStatefulWidget {
  const EntranceEffectUserSettingsPage({super.key});

  @override
  ConsumerState<EntranceEffectUserSettingsPage> createState() =>
      _EntranceEffectUserSettingsPageState();
}

class _EntranceEffectUserSettingsPageState
    extends ConsumerState<EntranceEffectUserSettingsPage> {
  var _preview = false;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(
      membershipCapabilityAllowsProvider(MembershipCapabilityKeys.entranceEffect),
    )) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.workspace_premium_outlined,
              message:
                  'Giriş efekti ayarları Gold, Diamond veya SVIP üyelikle açılır.',
              actionLabel: 'Üyelik',
              action: () => context.push('/premium-membership'),
            ),
          ),
        ),
      );
    }

    final tier = ref.watch(vipTierProvider);
    final settings = ref.watch(entranceEffectSettingsProvider);
    final notifier = ref.read(entranceEffectSettingsProvider.notifier);
    final theme = ref.watch(myEntranceThemeProvider);

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
                          title: 'Giriş efekti',
                          subtitle: 'Takım amblemi · Gold giriş',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      SettingsHeroCard(
                        title: 'Giriş efektim',
                        subtitle:
                            'Takımın renkleri ve amblemi odaya girişte üstten kayar',
                        leading: Icon(
                          Icons.auto_awesome_rounded,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SettingsSectionHeader(
                        'Görünüm',
                        icon: Icons.brush_rounded,
                      ),
                      SettingsPanel(
                        child: SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<EntranceVisualStyle>(
                            segments: const [
                              ButtonSegment(
                                value: EntranceVisualStyle.topTeamPass,
                                label: Text('Üstten'),
                                icon: Icon(Icons.vertical_align_top_rounded),
                              ),
                              ButtonSegment(
                                value: EntranceVisualStyle.centerFullscreen,
                                label: Text('Tam ekran'),
                                icon: Icon(Icons.fullscreen_rounded),
                              ),
                            ],
                            selected: {settings.visualStyle},
                            onSelectionChanged: (s) => notifier.update(
                              settings.copyWith(visualStyle: s.first),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SettingsTileGrid(
                        children: [
                          SettingsToggleTile(
                            icon: Icons.shield_rounded,
                            label: 'Takım renkleri ve amblem',
                            subtitle:
                                theme.teamName ?? 'Takım profilden okunur',
                            value: settings.teamColorsEnabled,
                            onChanged: (v) => notifier.update(
                              settings.copyWith(teamColorsEnabled: v),
                            ),
                          ),
                        ],
                      ),
                      const SettingsSectionHeader(
                        'Animasyon',
                        icon: Icons.speed_rounded,
                      ),
                      SettingsPanel(
                        child: Column(
                          children: [
                            _slider(
                              label: 'Hız',
                              value: settings.speed,
                              min: 0.6,
                              max: 2.0,
                              display: '${settings.speed.toStringAsFixed(1)}×',
                              onChanged: (v) => notifier
                                  .update(settings.copyWith(speed: v)),
                            ),
                            _slider(
                              label: 'Süre (ms)',
                              value: settings.durationMs.toDouble(),
                              min: 1400,
                              max: 4200,
                              display: '${settings.durationMs} ms',
                              onChanged: (v) => notifier.update(
                                settings.copyWith(durationMs: v.round()),
                              ),
                            ),
                            _slider(
                              label: 'Geçiş sayısı',
                              value: settings.passCount.toDouble(),
                              min: 1,
                              max: 3,
                              display: '${settings.passCount}',
                              onChanged: (v) => notifier.update(
                                settings.copyWith(passCount: v.round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => setState(() => _preview = true),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Önizleme'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_preview)
              GoldTeamTopEntranceBanner(
                userName: 'Siz',
                tier: tier,
                theme: settings.teamColorsEnabled
                    ? theme
                    : EntranceTheme.turkey,
                onFinished: () {
                  if (mounted) setState(() => _preview = false);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(display, style: const TextStyle(fontSize: 12)),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
