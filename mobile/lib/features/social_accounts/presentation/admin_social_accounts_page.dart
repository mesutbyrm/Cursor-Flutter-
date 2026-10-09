import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../admin/presentation/providers/staff_access_provider.dart';
import '../data/social_accounts_repository.dart';

/// Yönetim Merkezi → Sosyal Medya: sitenin resmi hesaplarını düzenler.
/// Kullanıcı adı (`@canlifal`) veya tam bağlantı girilebilir.
class AdminSocialAccountsPage extends ConsumerStatefulWidget {
  const AdminSocialAccountsPage({super.key});

  @override
  ConsumerState<AdminSocialAccountsPage> createState() =>
      _AdminSocialAccountsPageState();
}

class _AdminSocialAccountsPageState
    extends ConsumerState<AdminSocialAccountsPage> {
  final _controllers = <String, TextEditingController>{
    for (final p in kSocialPlatforms) p.$1: TextEditingController(),
  };
  final _enabled = <String, bool>{for (final p in kSocialPlatforms) p.$1: true};
  final _urls = <String, String>{};
  var _loading = true;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _apply(List<SiteSocialAccount> list) {
    _urls.clear();
    for (final a in list) {
      _controllers[a.platform]?.text = a.value;
      _enabled[a.platform] = a.enabled;
      if (a.url.isNotEmpty) _urls[a.platform] = a.url;
    }
  }

  Future<void> _load() async {
    try {
      final list =
          await ref.read(socialAccountsRepositoryProvider).fetchAdmin();
      if (!mounted) return;
      setState(() {
        _apply(list);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Hesaplar yüklenemedi.';
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref.read(socialAccountsRepositoryProvider).saveAdmin([
        for (final p in kSocialPlatforms)
          (
            platform: p.$1,
            value: _controllers[p.$1]!.text,
            enabled: _enabled[p.$1] ?? true,
          ),
      ]);
      ref.invalidate(siteSocialAccountsProvider);
      if (!mounted) return;
      setState(() => _apply(saved));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sosyal medya hesapları kaydedildi.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is ApiException ? e.message : 'Kaydedilemedi.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sosyal Medya Hesapları')),
      body: !access.isSiteAdmin
          ? const Center(child: Text('Bu sayfa yalnız yöneticiler içindir.'))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(
                      'Kullanıcı adı (@canlifal) veya tam bağlantı girin. '
                      'Boş bırakılan hesap uygulamada ve sitede gösterilmez.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    for (final p in kSocialPlatforms) _row(p.$1, p.$2),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('admin-social-save'),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text('Kaydet'),
                    ),
                  ],
                ),
    );
  }

  Widget _row(String id, String label) {
    final url = _urls[id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(socialPlatformIcon(id), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: Key('admin-social-$id'),
              controller: _controllers[id],
              maxLength: 200,
              decoration: InputDecoration(
                labelText: label,
                counterText: '',
                isDense: true,
              ),
            ),
          ),
          Switch(
            value: _enabled[id] ?? true,
            onChanged: (v) => setState(() => _enabled[id] = v),
          ),
          IconButton(
            tooltip: 'Aç',
            onPressed: url == null
                ? null
                : () => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
