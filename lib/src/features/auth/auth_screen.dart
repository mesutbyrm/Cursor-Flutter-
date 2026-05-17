import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_state.dart';
import '../../shared/ui.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _birthDate = TextEditingController(text: '1995-06-20');
  final _birthTime = TextEditingController(text: '14:30');
  final _referral = TextEditingController();
  bool _register = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _username.dispose();
    _birthDate.dispose();
    _birthTime.dispose();
    _referral.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF070311),
              Color(0xFF2E1065),
              Color(0xFFBE185D),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Center(child: BrandMark(size: 96, glow: true)),
                    const SizedBox(height: 18),
                    Text(
                      _register
                          ? 'CanlifalTV’ye katıl'
                          : 'CanlifalTV’ye giriş yap',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Canlı yayınlar, sesli odalar, fal danışmanları ve premium sosyal deneyim.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _ModeTabs(
                      register: _register,
                      onChanged: (value) => setState(() => _register = value),
                    ),
                    const SizedBox(height: 16),
                    if (_register) ...<Widget>[
                      _field(_name, 'Ad soyad', Icons.badge_outlined),
                      _gap,
                      _field(_username, 'Kullanıcı adı', Icons.alternate_email),
                      _gap,
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _field(
                              _birthDate,
                              'Doğum tarihi',
                              Icons.calendar_month,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              _birthTime,
                              'Doğum saati',
                              Icons.schedule,
                            ),
                          ),
                        ],
                      ),
                      _gap,
                      _field(
                        _referral,
                        'Davet kodu (opsiyonel)',
                        Icons.card_giftcard,
                      ),
                      _gap,
                    ],
                    _field(
                      _email,
                      'E-posta',
                      Icons.mail_outline,
                      keyboard: TextInputType.emailAddress,
                    ),
                    _gap,
                    _field(
                      _password,
                      'Şifre',
                      Icons.lock_outline,
                      obscure: !_passwordVisible,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: session.loading ? null : _forgotPassword,
                        child: const Text('Şifremi unuttum'),
                      ),
                    ),
                    if (session.error != null) ...<Widget>[
                      ErrorState(message: session.error!),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: session.loading ? null : _submit,
                      child: session.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_register ? 'Kayıt ol' : 'Giriş yap'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: session.loading
                          ? null
                          : () {
                              ref.read(sessionProvider).continueAsGuest();
                              context.go('/app');
                            },
                      icon: const Icon(Icons.explore),
                      label: const Text('Misafir olarak keşfet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        labelText: label,
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_register) {
        await ref
            .read(sessionProvider)
            .register(
              name: _name.text.trim(),
              username: _username.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
              birthDate: _birthDate.text.trim(),
              birthTime: _birthTime.text.trim(),
              referralCode: _referral.text.trim().isEmpty
                  ? null
                  : _referral.text.trim(),
            );
      } else {
        await ref
            .read(sessionProvider)
            .login(_email.text.trim(), _password.text);
      }
      if (mounted) context.go('/app');
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('İşlem başarısız: $error')),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiProvider).forgotPassword(_email.text.trim());
      messenger.showSnackBar(
        const SnackBar(content: Text('Şifre sıfırlama bağlantısı gönderildi.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Şifre sıfırlama endpointi yanıt vermedi.'),
        ),
      );
    }
  }

  static const SizedBox _gap = SizedBox(height: 12);
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.register, required this.onChanged});

  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          _tab('Giriş', !register, () => onChanged(false)),
          _tab('Kayıt', register, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _tab(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFF7C3AED) : Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
