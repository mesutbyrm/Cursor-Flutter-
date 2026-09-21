import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        elevation: 0,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final preferencesAsync = ref.watch(notificationPreferencesProvider);

          return preferencesAsync.when(
            data: (prefs) => SingleChildScrollView(
              child: Column(
                children: [
                  _buildSection(
                    'Hatırlatıcılar',
                    [
                      _buildPreferenceRow(
                        context,
                        ref,
                        'Günlük Hatırlatıcı',
                        prefs.dailyReminderEnabled,
                        'dailyReminderEnabled',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Saat: ${prefs.dailyReminderTime}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showTimePickerDialog(context, ref),
                              child: const Text('Değiştir'),
                            ),
                          ],
                        ),
                      ),
                      _buildPreferenceRow(
                        context,
                        ref,
                        'Seri Hatırlatıcısı',
                        prefs.streakReminderEnabled,
                        'streakReminderEnabled',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Saat: ${prefs.streakReminderTime}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showTimePickerDialog(context, ref),
                              child: const Text('Değiştir'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildSection(
                    'Bildirim Türleri',
                    [
                      _buildPreferenceRow(
                        context,
                        ref,
                        'Başarılar',
                        prefs.achievementsEnabled,
                        'achievementsEnabled',
                      ),
                      _buildPreferenceRow(
                        context,
                        ref,
                        'Sosyal Bildirimler',
                        prefs.socialEnabled,
                        'socialEnabled',
                      ),
                      if (prefs.socialEnabled)
                        Padding(
                          padding: const EdgeInsets.only(left: 32, right: 16, top: 8, bottom: 8),
                          child: Column(
                            children: [
                              _buildPreferenceRowInline(
                                'Beğeniler',
                                prefs.socialLikesEnabled,
                                (value) => _updatePreference(ref, 'socialLikesEnabled', value),
                              ),
                              _buildPreferenceRowInline(
                                'Yorumlar',
                                prefs.socialCommentsEnabled,
                                (value) => _updatePreference(ref, 'socialCommentsEnabled', value),
                              ),
                              _buildPreferenceRowInline(
                                'Paylaşımlar',
                                prefs.socialSharesEnabled,
                                (value) => _updatePreference(ref, 'socialSharesEnabled', value),
                              ),
                            ],
                          ),
                        ),
                      _buildPreferenceRow(
                        context,
                        ref,
                        'Yeni Özellikler',
                        prefs.featuresEnabled,
                        'featuresEnabled',
                      ),
                    ],
                  ),
                  _buildSection(
                    'Bildirim Kanalları',
                    [
                      _buildPreferenceRow(
                        context,
                        ref,
                        'Push Bildirimleri',
                        prefs.pushEnabled,
                        'pushEnabled',
                      ),
                      _buildPreferenceRow(
                        context,
                        ref,
                        'E-posta Bildirimleri',
                        prefs.emailEnabled,
                        'emailEnabled',
                      ),
                      _buildPreferenceRow(
                        context,
                        ref,
                        'Uygulama İçi Bildirimler',
                        prefs.inAppEnabled,
                        'inAppEnabled',
                      ),
                    ],
                  ),
                  _buildSection(
                    'Sessiz Saatler',
                    [
                      _buildPreferenceRow(
                        context,
                        ref,
                        'Sessiz Saatler Etkin',
                        prefs.quietHoursEnabled,
                        'quietHoursEnabled',
                      ),
                      if (prefs.quietHoursEnabled)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Başlama: ${prefs.quietHoursStart}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showTimePickerDialog(context, ref),
                                    child: const Text('Değiştir'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Bitiş: ${prefs.quietHoursEnd}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showTimePickerDialog(context, ref),
                                    child: const Text('Değiştir'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Test Bildirimi Gönder'),
                        onPressed: () => _sendTestNotification(context, ref),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text('Hata: $err'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.cyan,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow(
    BuildContext context,
    WidgetRef ref,
    String label,
    bool value,
    String key,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: value,
            onChanged: (newValue) => _updatePreference(ref, key, newValue),
            activeColor: Colors.cyan,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRowInline(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.cyan,
          ),
        ],
      ),
    );
  }

  void _updatePreference(WidgetRef ref, String key, bool value) {
    final updateNotifier = ref.read(updatePreferencesProvider.notifier);
    updateNotifier.updatePreferences({
      key: value,
    });
    ref.invalidate(notificationPreferencesProvider);
  }

  void _showTimePickerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saat Seç'),
        content: const Text('Zaman seçme özelliği yakında gelecek'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _sendTestNotification(BuildContext context, WidgetRef ref) {
    final service = ref.read(notificationServiceProvider);
    service.sendTestNotification();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test bildirimi gönderildi'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
