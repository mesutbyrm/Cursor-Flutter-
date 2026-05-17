import 'package:flutter/material.dart';

import '../../shared/ui.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String, String)>[
      (
        Icons.people,
        'Kullanıcı yönetimi',
        'Roller, üyelikler ve hesap kontrolleri',
      ),
      (Icons.live_tv, 'Yayın yönetimi', 'Canlı yayın izleme ve sonlandırma'),
      (Icons.report, 'Şikayet sistemi', 'İçerik ve kullanıcı raporları'),
      (
        Icons.monetization_on,
        'Coin yönetimi',
        'Paketler, hareketler ve çekimler',
      ),
      (Icons.analytics, 'İstatistik', 'Gelir, yayın ve etkileşim raporları'),
      (Icons.shield, 'Moderasyon', 'Sohbet, oda ve içerik kontrolü'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Paneli')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const SectionHeader(title: 'Yönetim merkezi'),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Row(
                  children: <Widget>[
                    Icon(item.$1),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.$2,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(item.$3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
