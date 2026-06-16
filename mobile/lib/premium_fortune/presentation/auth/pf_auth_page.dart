import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pf_theme.dart';
import '../auth/pf_auth_view_model.dart';
import '../widgets/pf_glass_card.dart';

class PfAuthPage extends ConsumerStatefulWidget {
  const PfAuthPage({super.key});

  @override
  ConsumerState<PfAuthPage> createState() => _PfAuthPageState();
}

class _PfAuthPageState extends ConsumerState<PfAuthPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final vm = ref.read(pfAuthViewModelProvider.notifier);
    String? error;
    if (_isRegister) {
      error = await vm.register(
        _emailCtrl.text,
        _passCtrl.text,
        _nameCtrl.text,
      );
    } else {
      error = await vm.signInWithEmail(_emailCtrl.text, _passCtrl.text);
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      context.go('/premium');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PfTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [PfTheme.gold, PfTheme.purple],
                ).createShader(b),
                child: const Text(
                  'Mistik Fal',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Premium fal deneyimine hoş geldiniz',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white60,
                    ),
              ),
              const SizedBox(height: 40),
              PfGlassCard(
                child: Column(
                  children: [
                    if (_isRegister)
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    if (_isRegister) const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isRegister ? 'Kayıt Ol' : 'Giriş Yap'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isRegister = !_isRegister),
                      child: Text(
                        _isRegister
                            ? 'Zaten hesabınız var mı? Giriş yapın'
                            : 'Hesabınız yok mu? Kayıt olun',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'veya',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              _SocialButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Google ile devam et',
                onTap: () async {
                  final err =
                      await ref.read(pfAuthViewModelProvider.notifier).signInWithGoogle();
                  if (!context.mounted) return;
                  if (err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  } else {
                    context.go('/premium');
                  }
                },
              ),
              const SizedBox(height: 10),
              _SocialButton(
                icon: Icons.apple,
                label: 'Apple ile devam et',
                onTap: () async {
                  final err =
                      await ref.read(pfAuthViewModelProvider.notifier).signInWithApple();
                  if (!context.mounted) return;
                  if (err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  } else {
                    context.go('/premium');
                  }
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(pfAuthViewModelProvider.notifier).continueAsGuest();
                  context.go('/premium');
                },
                child: const Text('Misafir olarak devam et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: PfTheme.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
