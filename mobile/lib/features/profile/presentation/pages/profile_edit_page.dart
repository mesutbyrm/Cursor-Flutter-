import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
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
    });
  }

  @override
  void dispose() {
    _displayCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
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
      await ref.read(authControllerProvider.notifier).refreshMe();
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
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Profili Düzenle',
          subtitle: 'Fotoğraf, kullanıcı adı ve hakkında',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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
                          backgroundColor: AppColors.accentPink,
                          child: const Icon(Icons.camera_alt_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickAvatar,
                  child: const Text('Profil fotoğrafını değiştir'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _avatarUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Profil fotoğrafı URL (isteğe bağlı)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayCtrl,
                decoration: const InputDecoration(labelText: 'Görünen ad'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Kullanıcı adı'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioCtrl,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Hakkında',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
