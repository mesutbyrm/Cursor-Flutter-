import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/share_settings_provider.dart';

class ShareSettingsScreen extends ConsumerWidget {
  const ShareSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sosyal Ağlara Paylaşım'),
        elevation: 0,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final settingsAsync = ref.watch(shareSettingsProvider(''));

          return settingsAsync.when(
            data: (settings) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Etkinleştirilmiş Platformlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPlatformTile(
                      'Instagram',
                      Icons.camera_alt,
                      settings.instagramEnabled,
                      () {},
                    ),
                    _buildPlatformTile(
                      'TikTok',
                      Icons.music_note,
                      settings.tiktokEnabled,
                      () {},
                    ),
                    _buildPlatformTile(
                      'Twitter',
                      Icons.chat,
                      settings.twitterEnabled,
                      () {},
                    ),
                    _buildPlatformTile(
                      'Facebook',
                      Icons.people,
                      settings.facebookEnabled,
                      () {},
                    ),
                    _buildPlatformTile(
                      'WhatsApp',
                      Icons.phone,
                      settings.whatsappEnabled,
                      () {},
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Gizlilik Ayarları',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Varsayılan Gizlilik: ${settings.defaultPrivacy}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              title: const Text('Yorumlara İzin Ver'),
                              value: settings.allowComments,
                              onChanged: (_) {},
                            ),
                            SwitchListTile(
                              title: const Text('Paylaşımlara İzin Ver'),
                              value: settings.allowShares,
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Hata: $err')),
          );
        },
      ),
    );
  }

  Widget _buildPlatformTile(String platform, IconData icon, bool enabled, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple[400]),
        title: Text(platform),
        trailing: Switch(
          value: enabled,
          onChanged: (_) => onTap(),
        ),
      ),
    );
  }
}
