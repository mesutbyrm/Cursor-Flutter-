import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../providers/social_providers.dart';

/// Hikâye ekleme — galeriden görsel veya video.
Future<bool> showStoryCreateSheet(BuildContext context, WidgetRef ref) async {
  final choice = await showModalBottomSheet<_StoryMediaChoice>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hikâye ekle',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Galeriden fotoğraf'),
              onTap: () => Navigator.pop(ctx, _StoryMediaChoice.image),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Galeriden video'),
              subtitle: const Text('En fazla 60 sn önerilir'),
              onTap: () => Navigator.pop(ctx, _StoryMediaChoice.video),
            ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return false;

  final picker = ImagePicker();
  try {
    if (choice == _StoryMediaChoice.image) {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null || !context.mounted) return false;
      await ref.read(socialRepositoryProvider).createStoryImage(picked.path);
    } else {
      final picked = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked == null || !context.mounted) return false;
      await ref.read(socialRepositoryProvider).createStoryVideo(picked.path);
    }
    ref.invalidate(socialStoryRingsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hikâyen paylaşıldı')),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
    return false;
  }
}

enum _StoryMediaChoice { image, video }
