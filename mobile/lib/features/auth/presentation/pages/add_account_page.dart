import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/saved_accounts_store.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';
import '../widgets/premium_auth_2026/premium_auth_2026.dart';

/// Oturum açıkken ikinci (… beşinci) hesabı ekler. Giriş başarısız olursa
/// mevcut hesap aktif kalır; başarılıysa yeni hesap aktif olur ve önceki
/// hesap profil başlığındaki hesap değiştiriciden geri seçilebilir.
class AddAccountPage extends ConsumerStatefulWidget {
  const AddAccountPage({super.key});

  @override
  ConsumerState<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends ConsumerState<AddAccountPage> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthController c) action) async {
    final previousId = ref.read(authControllerProvider).valueOrNull?.id;
    try {
      await action(ref.read(authControllerProvider.notifier));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
      return;
    }
    if (!mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || user.id == previousId) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.display} hesabı eklendi')),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authUserActionBusyProvider);
    final accounts = ref.watch(savedAccountsListProvider).valueOrNull;
    final full = accounts != null && accounts.length >= maxSavedAccounts;

    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF05050D),
        appBar: AppBar(
          title: const Text('Hesap ekle'),
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    full
                        ? 'En fazla $maxSavedAccounts hesap eklenebilir. '
                            'Yeni hesap için Hesapları yönet bölümünden '
                            'bir hesabı kaldırın.'
                        : 'Mevcut hesabınız açık kalır. Hesaplar arasında '
                            'profilinizdeki kullanıcı adına dokunarak '
                            'geçiş yapabilirsiniz.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AuthSocialSection(
                    busy: busy,
                    googleLabel: 'Google ile hesap ekle',
                    onGoogle: busy || full
                        ? null
                        : () => _run((c) => c.addAccountWithGoogle()),
                    onApple: busy || full
                        ? null
                        : () => _run((c) => c.addAccountWithApple()),
                  ),
                  const SizedBox(height: 22),
                  const AuthOrDividerPremium(),
                  const SizedBox(height: 22),
                  AuthFloatingField(
                    controller: _identifier,
                    label: 'E-posta veya kullanıcı adı',
                    hint: 'ornek@email.com veya kullanici_adi',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.text,
                    autofillHints: const [
                      AutofillHints.email,
                      AutofillHints.username,
                    ],
                    validator: (v) => v != null && v.trim().length >= 3
                        ? null
                        : 'En az 3 karakter',
                  ),
                  const SizedBox(height: 14),
                  AuthFloatingField(
                    controller: _password,
                    label: 'Şifre',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    validator: (v) =>
                        v != null && v.length >= 6 ? null : 'En az 6 karakter',
                  ),
                  const SizedBox(height: 20),
                  AuthNeonButton(
                    label: 'Hesabı ekle',
                    loading: busy,
                    onPressed: busy || full
                        ? null
                        : () async {
                            if (!_form.currentState!.validate()) return;
                            await _run(
                              (c) => c.addAccountWithPassword(
                                _identifier.text.trim(),
                                _password.text,
                              ),
                            );
                            if (mounted) _password.clear();
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
