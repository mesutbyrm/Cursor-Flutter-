import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_shell.dart';
import '../providers/profile_hub_providers.dart';
import '../providers/profile_providers.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _displayCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zodiacCtrl = TextEditingController();
  final _avatarUrlCtrl = TextEditingController();
  var _saving = false;
  String? _localAvatarDataUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (user == null || !mounted) return;
      _displayCtrl.text = user.display;
      _usernameCtrl.text = user.username;
      _bioCtrl.text = user.bio ?? '';
      _avatarUrlCtrl.text = user.avatarUrl ?? '';
      final ext = ref.read(profileExtendedProvider).valueOrNull;
      if (ext != null) {
        _cityCtrl.text = ext.city ?? '';
        _zodiacCtrl.text = ext.zodiacSign ?? '';
      }
    });
  }

  @override
  void dispose() {
    _displayCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _zodiacCtrl.dispose();
    _avatarUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 400_000) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görsel çok büyük; daha küçük bir fotoğraf seçin.')),
      );
      return;
    }
    final mime = file.mimeType ?? 'image/jpeg';
    setState(() {
      _localAvatarDataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final avatar = _localAvatarDataUrl ??
          (_avatarUrlCtrl.text.trim().isEmpty
              ? null
              : _avatarUrlCtrl.text.trim());
      await ref.read(profileRepositoryProvider).updateMe(
            displayName: _displayCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            avatarUrl: avatar,
          );
      try {
        await ref.read(profileRemoteProvider).updateProfile(
              displayName: _displayCtrl.text.trim(),
              bio: _bioCtrl.text.trim(),
              avatarUrl: avatar,
              city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
              zodiacSign:
                  _zodiacCtrl.text.trim().isEmpty ? null : _zodiacCtrl.text.trim(),
            );
      } catch (_) {}
      await ref.read(authControllerProvider.notifier).refreshMe();
      ref.invalidate(profileExtendedProvider);
      ref.invalidate(profileUserStatisticsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    final previewUrl = _localAvatarDataUrl ?? _avatarUrlCtrl.text.trim();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumScreenShell(
        child: DiscoverSubPage(
          title: 'Profili Düzenle',
          subtitle: 'Fotoğraf, kullanıcı adı ve hakkında',
          body: ListView(
            physics: PremiumMotion.listPhysics,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              LiquidGlassCard(
                elevated: true,
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            UserAvatar(
                              url: previewUrl.isEmpty ? null : previewUrl,
                              radius: 52,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppThemeColors.accentPink,
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickAvatar,
                      child: Text(
                        'Profil fotoğrafını değiştir',
                        style: PremiumTypography.label(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LiquidGlassCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _avatarUrlCtrl,
                      decoration: authInputDecoration(
                        labelText: 'Profil fotoğrafı URL (isteğe bağlı)',
                        prefixIcon: Icons.link_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _displayCtrl,
                      decoration: authInputDecoration(
                        labelText: 'Görünen ad',
                        prefixIcon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameCtrl,
                      decoration: authInputDecoration(
                        labelText: 'Kullanıcı adı',
                        prefixIcon: Icons.alternate_email_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bioCtrl,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: authInputDecoration(
                        labelText: 'Hakkında',
                        prefixIcon: Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityCtrl,
                      decoration: authInputDecoration(
                        labelText: 'Şehir',
                        prefixIcon: Icons.location_city_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _zodiacCtrl,
                      decoration: authInputDecoration(
                        labelText: 'Burç',
                        prefixIcon: Icons.star_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Kaydet',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
