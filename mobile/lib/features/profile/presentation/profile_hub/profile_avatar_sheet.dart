import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_hub_providers.dart';

/// Profil fotoğrafı alt sayfa — görüntüle, değiştir, kamera, galeri, sil.
Future<void> showProfileAvatarSheet(
  BuildContext context,
  WidgetRef ref, {
  required String? avatarUrl,
  required VoidCallback onUpdated,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF12081F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AvatarSheetBody(
      avatarUrl: avatarUrl,
      onUpdated: onUpdated,
    ),
  );
}

class _AvatarSheetBody extends ConsumerWidget {
  const _AvatarSheetBody({
    required this.avatarUrl,
    required this.onUpdated,
  });

  final String? avatarUrl;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            if (avatarUrl != null && avatarUrl!.isNotEmpty)
              UserAvatar(url: avatarUrl, radius: 48),
            const SizedBox(height: 20),
            _SheetTile(
              icon: Icons.visibility_rounded,
              label: 'Fotoğrafı Gör',
              onTap: avatarUrl == null || avatarUrl!.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      _showFullImage(context, avatarUrl!);
                    },
            ),
            _SheetTile(
              icon: Icons.photo_library_rounded,
              label: 'Galeriden Seç',
              onTap: () => _pickAndUpload(context, ref, ImageSource.gallery),
            ),
            _SheetTile(
              icon: Icons.photo_camera_rounded,
              label: 'Kameradan Çek',
              onTap: () => _pickAndUpload(context, ref, ImageSource.camera),
            ),
            _SheetTile(
              icon: Icons.edit_rounded,
              label: 'Fotoğrafı Değiştir',
              onTap: () => _pickAndUpload(context, ref, ImageSource.gallery),
            ),
            _SheetTile(
              icon: Icons.delete_outline_rounded,
              label: 'Sil',
              destructive: true,
              onTap: avatarUrl == null || avatarUrl!.isEmpty
                  ? null
                  : () => _deleteAvatar(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: UserAvatar(url: url, radius: 120),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null || !context.mounted) return;
    Navigator.pop(context);
    await _uploadFile(context, ref, File(file.path));
  }

  Future<void> _uploadFile(
    BuildContext context,
    WidgetRef ref,
    File file,
  ) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Fotoğraf yükleniyor…')),
      );
      final service = ref.read(profileAvatarServiceProvider);
      final url = await service.uploadAvatarFile(file);
      await service.saveAvatarUrl(url);
      await ref.read(authControllerProvider.notifier).refreshMe();
      await refreshProfileHub(ref);
      onUpdated();
      messenger?.showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  Future<void> _deleteAvatar(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref.read(profileAvatarServiceProvider).deleteAvatar();
      await ref.read(authControllerProvider.notifier).refreshMe();
      await refreshProfileHub(ref);
      onUpdated();
      messenger?.showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı silindi')),
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: destructive ? Colors.redAccent : Colors.white70,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: destructive ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}
