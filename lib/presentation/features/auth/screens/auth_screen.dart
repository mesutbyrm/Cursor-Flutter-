import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_mobile/presentation/providers/providers.dart';
import 'package:canlifal_mobile/presentation/widgets/shared_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: '',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '',
  );
  final TextEditingController _nameController = TextEditingController(text: '');
  bool _isRegister = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = ref.watch(authControllerProvider);

    return AnimatedGradientBackground(
      child: Scaffold(
        body: SafeArea(
          child: ResponsiveMaxWidth(
            maxWidth: 1120,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool wide = constraints.maxWidth > 820;
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Flex(
                      direction: wide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          flex: wide ? 5 : 1,
                          fit: wide ? FlexFit.tight : FlexFit.loose,
                          child: _HeroPanel(wide: wide),
                        ),
                        SizedBox(width: wide ? 28 : 0, height: wide ? 0 : 24),
                        Flexible(
                          flex: wide ? 4 : 1,
                          fit: wide ? FlexFit.tight : FlexFit.loose,
                          child: GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  _isRegister
                                      ? 'Canlifal hesabını oluştur'
                                      : 'Canlifal’a giriş yap',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Canlı fal, sosyal yayınlar, FanClub ve premium deneyim tek uygulamada.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 22),
                                if (_isRegister)
                                  TextField(
                                    controller: _nameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Görünen ad',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                  ),
                                if (_isRegister) const SizedBox(height: 14),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'E-posta',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Şifre',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _resetPassword(context),
                                    child: const Text('Şifremi unuttum'),
                                  ),
                                ),
                                if (auth.errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      auth.errorMessage!,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                FilledButton(
                                  onPressed: auth.isBusy ? null : _submit,
                                  child: auth.isBusy
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _isRegister
                                              ? 'Kayıt ol'
                                              : 'Giriş yap',
                                        ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () => setState(
                                    () => _isRegister = !_isRegister,
                                  ),
                                  child: Text(
                                    _isRegister
                                        ? 'Zaten hesabım var'
                                        : 'Yeni hesap oluştur',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final AuthController auth = ref.read(authControllerProvider);
    final bool success = _isRegister
        ? await auth.register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          )
        : await auth.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

    if (success && mounted) {
      context.go('/home');
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    await ref
        .read(authControllerProvider)
        .resetPassword(_emailController.text.trim());
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Şifre sıfırlama isteği gönderildi.')),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: .08),
          ),
          child: const Text('TikTok + Instagram + Discord hissi'),
        ),
        const SizedBox(height: 18),
        Text(
          'Canlı fal ve sosyal yayın dünyasına premium giriş.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const <Widget>[
            StatPill(icon: Icons.sensors, label: 'canlı', value: '128'),
            StatPill(icon: Icons.people, label: 'online', value: '42K'),
            StatPill(icon: Icons.auto_awesome, label: 'fal', value: '9.8K'),
          ],
        ),
      ],
    );
  }
}
