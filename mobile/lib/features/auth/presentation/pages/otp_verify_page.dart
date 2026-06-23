import 'package:canlifal_social/core/config/env.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_navigation.dart';
import '../providers/auth_providers.dart';
import '../widgets/premium_auth_2026/premium_auth_2026.dart';

/// 6 haneli e-posta doğrulama — mobil JWT API.
class OtpVerifyPage extends ConsumerStatefulWidget {
  const OtpVerifyPage({super.key, this.email});

  final String? email;

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  var _busy = false;
  var _resending = false;

  @override
  void initState() {
    super.initState();
    if (!Env.useMobileAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AuthNavigation.toForgotPassword(context);
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode(silent: true));
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

  String get _email =>
      widget.email?.trim() ??
      ref.read(authControllerProvider).valueOrNull?.email ??
      '';

  Future<void> _sendCode({bool silent = false}) async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendEmailVerification(email: _email.isNotEmpty ? _email : null);
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama kodu gönderildi')),
      );
    } catch (e) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

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

  Future<void> _verify() async {
    if (_busy || _code.length != 6) return;
    final email = _email;
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli e-posta bulunamadı')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).verifyEmail(
            email: email,
            code: _code,
          );
      await ref.read(authControllerProvider.notifier).refreshMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-posta doğrulandı')),
      );
      AuthNavigation.toLogin(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _email;

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
                  enabled: !_busy,
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
            label: _busy ? 'Doğrulanıyor…' : 'Doğrula',
            loading: _busy,
            onPressed: _code.length == 6 && !_busy ? _verify : null,
          ),
          const SizedBox(height: 12),
          AuthTextLinkPremium(
            label: _resending ? 'Gönderiliyor…' : 'Kodu tekrar gönder',
            onPressed: _resending ? null : () => _sendCode(),
          ),
        ],
      ),
    );
  }
}
