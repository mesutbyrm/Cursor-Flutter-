import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_state.dart';
import '../../shared/ui.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.onOpenAdmin});

  final VoidCallback onOpenAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = session.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: <Widget>[
        Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF312E81), Color(0xFFBE185D)],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -42),
          child: GlassCard(
            child: Column(
              children: <Widget>[
                AppAvatar(
                  imageUrl: user?.image ?? '',
                  fallback: user?.name ?? 'M',
                  radius: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  user?.name ?? 'Misafir',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '@${user?.username ?? 'misafir'} • Seviye ${user?.level ?? 1} • ${user?.membership ?? 'basic'}',
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _stat(compactCount(user?.followers ?? 0), 'Takipçi'),
                    _stat(compactCount(user?.following ?? 0), 'Takip'),
                    _stat(compactCount(user?.likes ?? 0), 'Beğeni'),
                    _stat(compactCount(user?.coins ?? 0), 'Coin'),
                  ],
                ),
              ],
            ),
          ),
        ),
        SectionHeader(title: 'Premium sistemler'),
        _menu(
          Icons.favorite,
          'FanClub üyelikleri',
          'Favori yayıncılarını destekle',
        ),
        _menu(
          Icons.workspace_premium,
          'Premium üyelik',
          'Gold rozetler ve özel odalar',
        ),
        _menu(
          Icons.card_giftcard,
          'Hediye geçmişi',
          'Gönderilen ve alınan hediyeler',
        ),
        _menu(
          Icons.shield,
          'Gizlilik ve engellenenler',
          'Engelleme, moderasyon ve güvenlik',
        ),
        _menu(
          Icons.admin_panel_settings,
          'Admin paneli',
          'Moderasyon, coin ve istatistik yönetimi',
          onTap: onOpenAdmin,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => ref.read(sessionProvider).logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Çıkış yap'),
        ),
      ],
    );
  }

  Widget _stat(String value, String label) => Column(
    children: <Widget>[
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
      ),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );

  Widget _menu(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GlassCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}
