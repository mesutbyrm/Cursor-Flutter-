import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/canlifal_brand_logo.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../../core/widgets/settings_kit.dart';

class ProfileAboutPage extends ConsumerWidget {
  const ProfileAboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    final cfcLabel = economyCurrencyLabel(ref, key: 'cfc');
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Hakkımızda',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Center(child: CanlifalBrandLogo.horizontal(height: 56)),
              const SizedBox(height: 20),
              SettingsPanel(
                title: 'CanlıFal',
                icon: Icons.auto_awesome_rounded,
                child: Text(
                  'Canlı yayın, sosyal paylaşım, sesli sohbet ve fal '
                  'deneyimlerini tek uygulamada bir araya getirir.',
                  style: TextStyle(
                    height: 1.5,
                    fontSize: 14,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SettingsSectionHeader('Neler var?'),
              SettingsTileGrid(
                children: [
                  SettingsTileCard(
                    icon: Icons.podcasts_rounded,
                    label: 'Canlı yayın',
                    subtitle: 'Hediye ekonomisi ve PK',
                    accent: context.liveRed,
                  ),
                  SettingsTileCard(
                    icon: Icons.dynamic_feed_rounded,
                    label: 'Sosyal akış',
                    subtitle: 'Paylaşımlar ve hikayeler',
                    accent: context.accentCyan,
                  ),
                  SettingsTileCard(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Fal & tarot',
                    subtitle: 'Canlı fal oturumları',
                    accent: context.accentPurple,
                  ),
                  SettingsTileCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Cüzdan',
                    subtitle: '$jetonLabel ve $cfcLabel',
                    accent: context.coinGold,
                  ),
                ],
              ),
              const SettingsSectionHeader('Bağlantılar'),
              SettingsTileGrid(
                children: [
                  SettingsTileCard(
                    icon: Icons.language_rounded,
                    label: 'Web sitesi',
                    subtitle: Env.siteOrigin,
                    onTap: () => launchUrl(Uri.parse(Env.siteOrigin)),
                  ),
                  SettingsTileCard(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Gizlilik',
                    subtitle: '${Env.siteOrigin}/gizlilik',
                    onTap: () =>
                        launchUrl(Uri.parse('${Env.siteOrigin}/gizlilik')),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Sürüm 1.0 · © CanlıFal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
