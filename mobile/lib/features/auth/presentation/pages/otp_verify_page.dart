import 'package:canlifal_social/core/config/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth_navigation.dart';
import '../widgets/premium_auth_2026/premium_auth_2026.dart';

/// 6 haneli OTP doğrulama — premium PIN girişi.
class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({super.key, this.email});

  final String? email;

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    if (Env.useMobileAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AuthNavigation.toForgotPassword(context);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigit(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
    }
    if (value.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    if (_code.length == 6) {
      _verify();
    }
  }

  void _verify() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Doğrulama kodu alındı. Şifre sıfırlama site üzerinden tamamlanır.',
        ),
      ),
    );
    AuthNavigation.toLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email ?? '';

    return AuthPremiumShell(
      showBack: true,
      onBack: () => AuthNavigation.back(context),
      topTitle: 'Kodu gir',
      topSubtitle: email.isNotEmpty
          ? '$email adresine gönderilen 6 haneli kod'
          : 'E-postanıza gönderilen 6 haneli kod',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              return SizedBox(
                width: 46,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _nodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF9B4DFF).withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF2D7A),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => _onDigit(i, v),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          AuthNeonButton(
            label: 'Doğrula',
            onPressed: _code.length == 6 ? _verify : null,
          ),
          const SizedBox(height: 12),
          AuthTextLinkPremium(
            label: 'Kodu tekrar gönder',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yeni kod gönderildi.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
