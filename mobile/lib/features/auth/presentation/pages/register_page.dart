import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_navigation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_date_pickers.dart';
import '../widgets/premium_auth_2026/premium_auth_2026.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  String _language = 'tr';

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showAuthBirthDatePicker(context, initial: _birthDate);
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickBirthTime() async {
    final picked = await showAuthBirthTimePicker(context, initial: _birthTime);
    if (picked != null) setState(() => _birthTime = picked);
  }

  Future<void> _openLegal(String path) async {
    final uri = Uri.parse('${Env.siteOrigin}$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _soon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label yakında aktif olacak.')),
    );
  }

  Future<void> _submitRegister() async {
    if (!_form.currentState!.validate()) return;
    if (_birthDate == null || _birthTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğum tarihi ve doğum saati zorunludur')),
      );
      return;
    }
    final birthDateStr = DateFormat('yyyy-MM-dd').format(_birthDate!);
    final birthTimeStr =
        '${_birthTime!.hour.toString().padLeft(2, '0')}:${_birthTime!.minute.toString().padLeft(2, '0')}';

    await ref.read(authControllerProvider.notifier).register(
          email: _email.text.trim(),
          password: _password.text,
          displayName: _displayName.text.trim(),
          username: _username.text.trim(),
          birthDate: birthDateStr,
          birthTime: birthTimeStr,
          language: _language,
        );
  }

  @override
  Widget build(BuildContext context) {
    final formBusy = ref.watch(authUserActionBusyProvider);
    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        ),
      );
    });

    return AuthPremiumShell(
      showBack: true,
      onBack: () => AuthNavigation.back(context),
      topTitle: 'Hesap oluştur',
      topSubtitle: 'Dakikalar içinde topluluğa katıl.',
      child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthSocialSection(
                busy: formBusy,
                googleLabel: 'Google ile Kayıt ol',
                onGoogle: formBusy
                    ? null
                    : () => ref
                        .read(authControllerProvider.notifier)
                        .loginWithGoogle(),
                onTikTok: formBusy
                    ? null
                    : () => ref
                        .read(authControllerProvider.notifier)
                        .loginWithTikTok(),
                onApple: () => _soon('Apple girişi'),
              ),
              const SizedBox(height: 18),
              const AuthOrDividerPremium(),
              const SizedBox(height: 18),
              AuthFloatingField(
                controller: _displayName,
                label: 'Adınız',
                hint: 'Ad Soyad',
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v != null && v.trim().length >= 2 ? null : 'Adınızı girin',
              ),
              const SizedBox(height: 12),
              AuthFloatingField(
                controller: _username,
                label: 'Kullanıcı adı',
                hint: 'ornek_kullanici',
                prefixIcon: Icons.alternate_email_rounded,
                validator: (v) {
                  if (v == null || v.trim().length < 3) {
                    return 'En az 3 karakter';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                    return 'Yalnızca harf, rakam ve _';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _BirthChip(
                    label: _birthDate == null
                        ? 'Doğum tarihi'
                        : formatBirthDate(_birthDate!),
                    onTap: _pickBirthDate,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _BirthChip(
                    label: _birthTime == null
                        ? 'Doğum saati'
                        : _birthTime!.format(context),
                    onTap: _pickBirthTime,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              AuthFloatingField(
                controller: _email,
                label: 'E-posta',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Geçerli e-posta',
              ),
              const SizedBox(height: 12),
              AuthFloatingField(
                controller: _password,
                label: 'Şifre',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                validator: (v) =>
                    v != null && v.length >= 8 ? null : 'En az 8 karakter',
              ),
              const SizedBox(height: 12),
              AuthFloatingField(
                controller: _password2,
                label: 'Şifre tekrar',
                prefixIcon: Icons.lock_reset_rounded,
                obscureText: true,
                validator: (v) =>
                    v == _password.text ? null : 'Şifreler eşleşmiyor',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _language,
                dropdownColor: const Color(0xFF1A1030),
                decoration: InputDecoration(
                  labelText: 'Dil',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF140A28).withValues(alpha: 0.72),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _language = v);
                },
              ),
              const SizedBox(height: 20),
              AuthNeonButton(
                label: 'Kayıt ol',
                loading: formBusy,
                onPressed: formBusy ? null : _submitRegister,
              ),
              AuthTextLinkPremium(
                label: 'Zaten hesabın var mı? Giriş yap',
                onPressed: () => AuthNavigation.back(context),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _openLegal('/gizlilik-politikasi'),
                      child: Text(
                        'Gizlilik',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _openLegal('/kullanim-sartlari'),
                      child: Text(
                        'Şartlar',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }
}

class _BirthChip extends StatelessWidget {
  const _BirthChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF140A28).withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.95),
            ),
          ),
        ),
      ),
    );
  }
}
