import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_shell.dart';
import '../widgets/google_sign_in_button.dart';

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
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('tr'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickBirthTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) setState(() => _birthTime = picked);
  }

  Future<void> _openLegal(String path) async {
    final uri = Uri.parse('${Env.siteOrigin}$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submitRegister() async {
    if (!_form.currentState!.validate()) return;
    final birthDateStr = _birthDate != null
        ? DateFormat('yyyy-MM-dd').format(_birthDate!)
        : null;
    final birthTimeStr = _birthTime != null
        ? '${_birthTime!.hour.toString().padLeft(2, '0')}:${_birthTime!.minute.toString().padLeft(2, '0')}'
        : null;

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
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        ),
      );
    });

    return AuthShell(
      showBack: true,
      onBack: () => context.pop(),
      useAppIcon: true,
      child: AuthFormCard(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrandHeader(
                title: 'Kayıt Ol',
                subtitle: 'Hesabını oluştur; fal ve sosyal dünyaya katıl.',
              ),
              const SizedBox(height: 16),
              GoogleSignInButton(
                label: 'Google ile Kayıt ol',
                onPressed: auth.isLoading
                    ? null
                    : () => ref
                        .read(authControllerProvider.notifier)
                        .loginWithGoogle(),
              ),
              if (Env.hasTikTokLogin) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () => ref
                          .read(authControllerProvider.notifier)
                          .loginWithTikTok(),
                  icon: const Icon(Icons.music_note_rounded, size: 20),
                  label: const Text('TikTok ile Kayıt ol'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const AuthOrDivider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayName,
                textCapitalization: TextCapitalization.words,
                decoration: authInputDecoration(
                  labelText: 'Adınız',
                  hintText: 'Ad Soyad',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                validator: (v) =>
                    v != null && v.trim().length >= 2 ? null : 'Adınızı girin',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _username,
                decoration: authInputDecoration(
                  labelText: 'Kullanıcı adı',
                  hintText: 'ornek_kullanici',
                  prefixIcon: Icons.alternate_email_rounded,
                ),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickBirthDate,
                      child: Text(
                        _birthDate == null
                            ? 'Doğum tarihi'
                            : DateFormat('dd.MM.yyyy').format(_birthDate!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickBirthTime,
                      child: Text(
                        _birthTime == null
                            ? 'Doğum saati'
                            : _birthTime!.format(context),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: authInputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icons.mail_outline_rounded,
                ),
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Geçerli e-posta',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: authInputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icons.lock_outline_rounded,
                ),
                validator: (v) =>
                    v != null && v.length >= 8 ? null : 'En az 8 karakter',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _password2,
                obscureText: true,
                decoration: authInputDecoration(
                  labelText: 'Şifre tekrar',
                  prefixIcon: Icons.lock_reset_rounded,
                ),
                validator: (v) =>
                    v == _password.text ? null : 'Şifreler eşleşmiyor',
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _language,
                decoration: authInputDecoration(
                  labelText: 'Dil tercihi',
                  prefixIcon: Icons.language_rounded,
                ),
                dropdownColor: AppColors.bgCard,
                items: const [
                  DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _language = v);
                },
              ),
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: 'Kayıt ol',
                loading: auth.isLoading,
                onPressed: auth.isLoading ? null : _submitRegister,
              ),
              const SizedBox(height: 8),
              AuthTextLink(
                label: 'Zaten hesabınız var mı? Giriş yap',
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _openLegal('/gizlilik-politikasi'),
                      child: Text(
                        'Gizlilik Politikası',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _openLegal('/kullanim-sartlari'),
                      child: Text(
                        'Kullanım Şartları',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
