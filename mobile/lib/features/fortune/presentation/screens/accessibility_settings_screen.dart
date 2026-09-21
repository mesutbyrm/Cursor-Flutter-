import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erişilebilirlik'),
        elevation: 0,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final settingsAsync = ref.watch(accessibilitySettingsProvider(''));
          final profileAsync = ref.watch(accessibilityProfileProvider(''));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Görme Ayarları',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                settingsAsync.when(
                  data: (settings) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Yüksek Kontrast'),
                              subtitle: const Text('Metin ve öğelerin daha belirgin olmasını sağlar'),
                              value: settings.highContrastEnabled,
                              onChanged: (_) {},
                            ),
                            SwitchListTile(
                              title: const Text('Büyük Metin'),
                              subtitle: const Text('Yazı boyutunu artırır'),
                              value: settings.largeTextEnabled,
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Hata: $err'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hareket Ayarları',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                settingsAsync.when(
                  data: (settings) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SwitchListTile(
                          title: const Text('Hareketi Azalt'),
                          subtitle: const Text('Animasyonları ve geçişleri devre dışı bırakır'),
                          value: settings.reduceMotionEnabled,
                          onChanged: (_) {},
                        ),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Hata: $err'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'İşitme Ayarları',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                settingsAsync.when(
                  data: (settings) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SwitchListTile(
                          title: const Text('Altyazılar'),
                          subtitle: const Text('Video ve ses içeriklerinde altyazı göster'),
                          value: settings.captionsEnabled,
                          onChanged: (_) {},
                        ),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Hata: $err'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Navigasyon Ayarları',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                settingsAsync.when(
                  data: (settings) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Ekran Okuyucu Desteği'),
                              subtitle: const Text('Ses ile içerik okuma'),
                              value: settings.screenReaderEnabled,
                              onChanged: (_) {},
                            ),
                            SwitchListTile(
                              title: const Text('Klavye Navigasyonu'),
                              subtitle: const Text('Uygulamayı yalnızca klavye ile kullanın'),
                              value: settings.keyboardNavigationEnabled,
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Hata: $err'),
                ),
                const SizedBox(height: 24),
                profileAsync.when(
                  data: (profile) {
                    final activeFeatures = profile['activeFeatures'] as List? ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Etkinleştirilmiş Özellikler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (activeFeatures.isEmpty)
                          const Text(
                            'Hiçbir erişilebilirlik özelliği etkinleştirilmedi',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            children: activeFeatures
                                .map((feature) => Chip(
                                      label: Text(feature),
                                      backgroundColor: Colors.cyan[100],
                                    ))
                                .toList(),
                          ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Hata: $err'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
