import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/canlifal_brand_logo.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class ProfileAboutPage extends StatelessWidget {
  const ProfileAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Hakkımızda',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const Center(child: CanlifalBrandLogo.horizontal(height: 56)),
              const SizedBox(height: 20),
              const Text(
                'CanlıFal, canlı yayın, sosyal paylaşım, sesli sohbet ve fal '
                'deneyimlerini tek uygulamada bir araya getirir.',
                style: TextStyle(height: 1.5, fontSize: 15),
              ),
              const SizedBox(height: 16),
              const Text(
                '• Canlı yayın ve hediye ekonomisi\n'
                '• Sosyal akış ve hikayeler\n'
                '• Fal & tarot oturumları\n'
                '• Jeton ve CFC cüzdanı',
                style: TextStyle(height: 1.6, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('Web sitesi'),
                subtitle: Text(Env.siteOrigin),
                onTap: () => launchUrl(Uri.parse(Env.siteOrigin)),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Gizlilik'),
                subtitle: Text('${Env.siteOrigin}/gizlilik'),
                onTap: () => launchUrl(Uri.parse('${Env.siteOrigin}/gizlilik')),
              ),
              const SizedBox(height: 12),
              Text(
                'Sürüm 1.0 · © CanlıFal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
