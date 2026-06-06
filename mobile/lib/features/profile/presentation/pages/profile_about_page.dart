import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/canlifal_brand_logo.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class ProfileAboutPage extends StatelessWidget {
  const ProfileAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Hakkımızda',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Center(child: CanlifalBrandLogo.horizontal(height: 56)),
              SizedBox(height: 20),
              Text(
                'CanlıFal, canlı yayın, sosyal paylaşım, sesli sohbet ve fal '
                'deneyimlerini tek uygulamada bir araya getirir.',
                style: TextStyle(height: 1.5, fontSize: 15),
              ),
              SizedBox(height: 16),
              Text(
                '• Canlı yayın ve hediye ekonomisi\n'
                '• Sosyal akış ve hikayeler\n'
                '• Fal & tarot oturumları\n'
                '• Jeton ve CFC cüzdanı',
                style: TextStyle(height: 1.6, color: context.colors.onSurfaceVariant),
              ),
              SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.language_rounded),
                title: Text('Web sitesi'),
                subtitle: Text(Env.siteOrigin),
                onTap: () => launchUrl(Uri.parse(Env.siteOrigin)),
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('Gizlilik'),
                subtitle: Text('${Env.siteOrigin}/gizlilik'),
                onTap: () => launchUrl(Uri.parse('${Env.siteOrigin}/gizlilik')),
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
