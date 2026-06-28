import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../core/di/pf_providers.dart';
import '../../core/theme/pf_theme.dart';
import '../auth/pf_auth_view_model.dart';
import '../widgets/pf_glass_card.dart';

class PfProfilePage extends ConsumerStatefulWidget {
  const PfProfilePage({super.key});

  @override
  ConsumerState<PfProfilePage> createState() => _PfProfilePageState();
}

class _PfProfilePageState extends ConsumerState<PfProfilePage> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(pfEffectiveUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/premium/auth'),
            child: const Text('Giriş Yap'),
          ),
        ),
      );
    }

    _nameCtrl.text = user.displayName;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PfGlassCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: PfTheme.purple,
                  backgroundImage:
                      user.photoUrl != null ? canlifalImageProvider(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName[0],
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(user.email,
                    style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(label: 'Kredi', value: '${user.credits}'),
                    _Stat(label: 'Puan', value: '${user.points}'),
                    _Stat(label: 'Rozet', value: '${user.badges.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Görünen Ad',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final err = await ref
                    .read(pfAuthViewModelProvider.notifier)
                    .updateProfile(displayName: _nameCtrl.text.trim());
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'Profil güncellendi')),
                );
              },
              child: const Text('Kaydet'),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Yönetim Paneli'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/premium/admin'),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Çıkış Yap'),
            onTap: () async {
              await ref.read(pfAuthViewModelProvider.notifier).signOut();
              if (context.mounted) context.go('/premium/auth');
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: PfTheme.gold,
            )),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class PfAdminPage extends StatelessWidget {
  const PfAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('Kullanıcı Yönetimi', Icons.people_outline, '12.450 aktif kullanıcı'),
      ('Falcı Yönetimi', Icons.mic_external_on_outlined, '48 onaylı falcı'),
      ('Gelir Raporları', Icons.bar_chart_rounded, 'Bu ay: ₺284.500'),
      ('Kampanya Yönetimi', Icons.campaign_outlined, '3 aktif kampanya'),
      ('İçerik Yönetimi', Icons.article_outlined, 'Burç & fal içerikleri'),
    ];

    return Scaffold(
      backgroundColor: PfTheme.surface,
      appBar: AppBar(title: const Text('Yönetim Paneli')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PfGlassCard(
            child: Text(
              'Admin paneli — production\'da Firebase Admin + web dashboard ile entegre edilir.',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          const SizedBox(height: 16),
          ...sections.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PfGlassCard(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${s.$1} — web panel bağlantısı')),
                  );
                },
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(s.$2, color: PfTheme.purple),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$1,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(s.$3,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
