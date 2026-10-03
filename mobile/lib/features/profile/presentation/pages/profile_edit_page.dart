import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_shell.dart';
import '../../../vip_gold/domain/entrance_theme.dart';
import '../../../../core/membership/membership_capability_keys.dart';
import '../../../../core/membership/membership_capability_providers.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../premium_2026/widgets/profile_membership_manage_tile.dart';
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
  String? _favoriteTeam;

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
        _favoriteTeam = TeamCatalog.labelForKey(ext.favoriteTeam) ?? ext.favoriteTeam;
      }
      setState(() {});
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
      String? avatarUrl = _avatarUrlCtrl.text.trim().isEmpty
          ? null
          : _avatarUrlCtrl.text.trim();
      if (_localAvatarDataUrl != null && _localAvatarDataUrl!.startsWith('data:')) {
        final comma = _localAvatarDataUrl!.indexOf(',');
        if (comma > 0) {
          final raw = base64Decode(_localAvatarDataUrl!.substring(comma + 1));
          if (raw.length > 400_000) {
            throw const ApiException(
              'Görsel çok büyük; daha küçük bir fotoğraf seçin.',
            );
          }
          final tmp = File(
            '${Directory.systemTemp.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await tmp.writeAsBytes(raw, flush: true);
          avatarUrl = await ref
              .read(profileAvatarServiceProvider)
              .uploadAvatarFile(tmp);
          await ref.read(profileAvatarServiceProvider).saveAvatarUrl(avatarUrl);
          try {
            await tmp.delete();
          } catch (_) {}
        }
      }

      await ref.read(profileRepositoryProvider).updateMe(
            displayName: _displayCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            avatarUrl: avatarUrl,
            favoriteTeam: _favoriteTeam,
          );
      try {
        await ref.read(profileRemoteProvider).updateProfile(
              displayName: _displayCtrl.text.trim(),
              bio: _bioCtrl.text.trim(),
              avatarUrl: avatarUrl,
              city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
              zodiacSign:
                  _zodiacCtrl.text.trim().isEmpty ? null : _zodiacCtrl.text.trim(),
              favoriteTeam: _favoriteTeam,
            );
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pop(true);
      unawaited(
        ref.read(authControllerProvider.notifier).refreshMe(force: true).timeout(
              const Duration(seconds: 12),
              onTimeout: () => null,
            ),
      );
      ref.invalidate(profileExtendedProvider);
      ref.invalidate(profileUserStatisticsProvider);
      ref.invalidate(walletBalancesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    int? maxLength,
    IconData? icon,
  }) async {
    final edit = TextEditingController(text: controller.text);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: edit,
              autofocus: true,
              maxLines: maxLines,
              maxLength: maxLength,
              decoration: authInputDecoration(
                labelText: label,
                prefixIcon: icon ?? Icons.edit_rounded,
              ),
            ),
            const SizedBox(height: 12),
            AuthPrimaryButton(
              label: 'Tamam',
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );
    final value = edit.text;
    edit.dispose();
    if (ok == true && mounted) setState(() => controller.text = value);
  }

  Widget _fieldRow({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    int? maxLength,
    IconData? icon,
    String placeholder = 'Ekle',
  }) {
    final c = context.colors;
    final value = controller.text.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _saving
            ? null
            : () => _editField(
                  label: label,
                  controller: controller,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  icon: icon,
                ),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: mockCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mockCardBorder(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: c.onSurfaceMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.isEmpty ? placeholder : value,
                      maxLines: maxLines == 1 ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: value.isEmpty ? c.onSurfaceMuted : c.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: c.onSurfaceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _localAvatarDataUrl ?? _avatarUrlCtrl.text.trim();
    final membershipInfo = ref.watch(profileMembershipInfoProvider);
    final membershipSectionTitle = buildMembershipProfileEditSectionTitle(
      info: membershipInfo,
    );
    final c = context.colors;
    const gap = SizedBox(height: 8);

    return MockScaffold(
      title: 'Profil Düzenle',
      body: ListView(
        physics: PremiumMotion.listPhysics,
        padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 14, 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFF8B5CF6)],
                  ),
                ),
                child: UserAvatar(
                  url: previewUrl.isEmpty ? null : previewUrl,
                  radius: 38,
                ),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _pickAvatar,
              child: Text(
                'Fotoğraf Değiştir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.onSurfaceVariant,
                ),
              ),
            ),
          ),
          _fieldRow(label: 'Ad', controller: _displayCtrl, icon: Icons.badge_outlined),
          gap,
          _fieldRow(
            label: 'Kullanıcı Adı',
            controller: _usernameCtrl,
            icon: Icons.alternate_email_rounded,
          ),
          gap,
          _fieldRow(
            label: 'Biyografi',
            controller: _bioCtrl,
            maxLines: 4,
            maxLength: 500,
            icon: Icons.notes_rounded,
          ),
          gap,
          _fieldRow(
            label: 'Konum',
            controller: _cityCtrl,
            icon: Icons.location_city_rounded,
            placeholder: 'Şehir ekle',
          ),
          gap,
          _fieldRow(label: 'Burç', controller: _zodiacCtrl, icon: Icons.star_outline_rounded),
          gap,
          _fieldRow(
            label: 'Profil fotoğrafı URL (isteğe bağlı)',
            controller: _avatarUrlCtrl,
            icon: Icons.link_rounded,
          ),
          gap,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: mockCardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mockCardBorder(context)),
            ),
            child: DropdownButtonFormField<String?>(
              initialValue: _favoriteTeam,
              decoration: const InputDecoration(
                labelText: 'Tuttuğu takım (giriş banner renkleri)',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Seçilmedi — 🇹🇷 varsayılan'),
                ),
                ...TeamCatalog.labels.map(
                  (label) => DropdownMenuItem<String?>(
                    value: label,
                    child: Text(label),
                  ),
                ),
              ],
              onChanged: _saving ? null : (v) => setState(() => _favoriteTeam = v),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mockCardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mockCardBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  membershipSectionTitle,
                  style: PremiumTypography.label(context).copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const ProfileMembershipManageTile(),
                if (ref.watch(
                  membershipCapabilityAllowsProvider(
                    MembershipCapabilityKeys.entranceEffect,
                  ),
                )) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.vertical_align_top_rounded),
                    title: const Text('Giriş efekti ayarları'),
                    subtitle: const Text('Takım amblemi, hız ve üstten geçiş'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/entrance-effects'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'Kaydet',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
