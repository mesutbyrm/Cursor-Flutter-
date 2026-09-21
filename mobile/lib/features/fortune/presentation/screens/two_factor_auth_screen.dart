import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/two_factor_auth_provider.dart';

class TwoFactorAuthScreen extends ConsumerWidget {
  const TwoFactorAuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İki Faktörlü Kimlik Doğrulama'),
        elevation: 0,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final statusAsync = ref.watch(twoFactorStatusProvider(''));

          return statusAsync.when(
            data: (status) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Durum',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status.enabled ? Colors.green[100] : Colors.red[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status.enabled ? 'Etkin' : 'Devre dışı',
                                    style: TextStyle(
                                      color: status.enabled ? Colors.green[700] : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (status.enabled) ...[
                              Text(
                                'Yöntem: ${status.method ?? 'TOTP'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Yedek Kodları Kalan: ${status.backupCodesRemaining}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('2FA\'yı Devre Dışı Bırak'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {},
                              ),
                            ] else ...[
                              const Text(
                                '2FA etkinleştirerek hesabınızı daha güvenli hale getirin',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.security, size: 16),
                                label: const Text('2FA\'yı Etkinleştir'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[400],
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Bilgi',
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
                            const Text(
                              'İki faktörlü kimlik doğrulama nedir?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Hesabınıza erişmek için şifrenizin yanı sıra bir doğrulama kodu gerekir.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Desteklenen Yöntemler',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildMethodInfo('TOTP', 'Authenticator uygulaması ile zaman tabanlı kod'),
                            _buildMethodInfo('Yedek Kodları', 'Acil durumlarda kullanılan kodlar'),
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

  Widget _buildMethodInfo(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green[400], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
