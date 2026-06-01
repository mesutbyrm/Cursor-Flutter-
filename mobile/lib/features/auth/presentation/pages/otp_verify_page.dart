import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_shell.dart';

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
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email ?? '';

    return AuthShell(
      showBack: true,
      child: AuthFormCard(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBrandHeader(
            title: 'Kodu gir',
            subtitle: email.isNotEmpty
                ? '$email adresine gönderilen 6 haneli kod'
                : 'E-postanıza gönderilen 6 haneli kod',
          ),
          SizedBox(height: 32),
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurface,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppThemeColors.accentPink,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => _onDigit(i, v),
                ),
              );
            }),
          ),
          SizedBox(height: 28),
          AuthPrimaryButton(
            label: 'Doğrula',
            onPressed: _code.length == 6 ? _verify : null,
          ),
          SizedBox(height: 12),
          AuthTextLink(
            label: 'Kodu tekrar gönder',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yeni kod gönderildi.')),
              );
            },
          ),
        ],
        ),
      ),
    );
  }
}
