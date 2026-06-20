import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feed/presentation/widgets/discover/discover_glass_card.dart';
import '../providers/admin_voice_room_providers.dart';

/// Admin — sesli oda gelir oranları (backend hesaplar, burada yalnızca ayar).
class AdminVoiceRoomSettingsPanel extends ConsumerStatefulWidget {
  const AdminVoiceRoomSettingsPanel({super.key});

  @override
  ConsumerState<AdminVoiceRoomSettingsPanel> createState() =>
      _AdminVoiceRoomSettingsPanelState();
}

class _AdminVoiceRoomSettingsPanelState
    extends ConsumerState<AdminVoiceRoomSettingsPanel> {
  final _controllers = <String, TextEditingController>{};
  var _dirty = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _c(String key, Map<String, dynamic> data) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: '${data[key] ?? ''}'),
    );
  }

  Future<void> _save() async {
    final patch = <String, dynamic>{};
    for (final e in _controllers.entries) {
      final v = int.tryParse(e.value.text.trim());
      if (v != null) patch[e.key] = v;
    }
    await saveAdminVoiceRoomSettings(ref, patch);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesli oda ayarları kaydedildi')),
      );
      setState(() => _dirty = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(adminVoiceRoomSettingsProvider);
    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Ayarlar yüklenemedi: $e'),
      ),
      data: (data) {
        if (data.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Sesli oda ayarları bu ortamda kullanılamıyor.'),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Text(
              'Voice Room Settings',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Hediye ve müzik gelir oranları sunucuda uygulanır.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            DiscoverGlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field('giftReceiverPercent', 'Gift Receiver %', data),
                  _field('roomOwnerPercent', 'Room Owner %', data),
                  _field('siteCommissionPercent', 'Site Commission %', data),
                  const Divider(height: 24),
                  _field('musicOwnerPercent', 'Music Owner % (Normal)', data),
                  _field('musicSitePercent', 'Music Site % (Normal)', data),
                  _field('vipMusicOwnerPercent', 'VIP Music Owner %', data),
                  _field('vipMusicSitePercent', 'VIP Music Site %', data),
                  _field('musicRequestCost', 'Müzik isteği (jeton)', data),
                  const Divider(height: 24),
                  _field('freeRoomMaxUsers', 'Ücretsiz oda max kişi', data),
                  _field('normalRoomMaxUsers', 'Normal oda max kişi', data),
                  _field('vipRoomMaxUsers', 'VIP oda max kişi', data),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _dirty ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppThemeColors.accentPurple,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Widget _field(String key, String label, Map<String, dynamic> data) {
    final controller = _c(key, data);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() => _dirty = true),
      ),
    );
  }
}
