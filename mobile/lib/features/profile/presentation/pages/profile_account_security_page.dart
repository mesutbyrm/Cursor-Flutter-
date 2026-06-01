import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/profile_providers.dart';

class ProfileAccountSecurityPage extends ConsumerStatefulWidget {
  const ProfileAccountSecurityPage({super.key});

  @override
  ConsumerState<ProfileAccountSecurityPage> createState() =>
      _ProfileAccountSecurityPageState();
}

class _ProfileAccountSecurityPageState
    extends ConsumerState<ProfileAccountSecurityPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni şifre en az 8 karakter olmalı')),
      );
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreler eşleşmiyor')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateMe(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre güncellendi')),
      );
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Hesap Güvenliği',
          subtitle: 'Şifre ve oturum',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ListTile(
                leading: Icon(Icons.verified_user_outlined),
                title: Text('İki adımlı doğrulama'),
                subtitle: Text('Yakında — SMS / e-posta OTP'),
                trailing: Icon(Icons.schedule_rounded),
              ),
              const Divider(),
              TextField(
                controller: _currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mevcut şifre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni şifre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni şifre (tekrar)'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _changePassword,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Şifreyi güncelle'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Tüm cihazlardan çıkış'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
