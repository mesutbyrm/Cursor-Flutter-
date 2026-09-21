import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_preferences_provider.dart';

class UserPreferencesScreen extends ConsumerWidget {
  const UserPreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tercihler'),
        elevation: 0,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final preferencesAsync = ref.watch(userPreferencesProvider(''));
          final animationAsync = ref.watch(animationConfigProvider(''));

          return preferencesAsync.when(
            data: (preferences) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Görünüm',
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
                          children: [
                            ListTile(
                              title: const Text('Tema'),
                              trailing: Text(preferences.theme),
                            ),
                            ListTile(
                              title: const Text('Vurgu Rengi'),
                              trailing: Text(preferences.accentColor),
                            ),
                            ListTile(
                              title: const Text('Yazı Boyutu'),
                              trailing: Text(preferences.fontSize),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sesler & Haptik',
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
                          children: [
                            SwitchListTile(
                              title: const Text('Sesler'),
                              value: preferences.soundEnabled,
                              onChanged: (_) {},
                            ),
                            SwitchListTile(
                              title: const Text('Haptik Geri Bildirim'),
                              value: preferences.hapticEnabled,
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Animasyonlar',
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
                          children: [
                            SwitchListTile(
                              title: const Text('Animasyonları Etkinleştir'),
                              value: preferences.animationsEnabled,
                              onChanged: (_) {},
                            ),
                            animationAsync.when(
                              data: (animation) {
                                return Column(
                                  children: [
                                    ListTile(
                                      title: const Text('Sayfa Geçişi'),
                                      trailing: Text('${animation.pageTransitionDuration}ms'),
                                    ),
                                    ListTile(
                                      title: const Text('Kart Döndürme'),
                                      trailing: Text('${animation.cardFlipDuration}ms'),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (err, stack) => Text('Hata: $err'),
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
}
