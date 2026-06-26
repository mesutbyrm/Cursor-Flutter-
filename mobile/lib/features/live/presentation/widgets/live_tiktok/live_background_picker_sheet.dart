import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Yayın arka planı — hazır görseller + galeri.
class LiveBackgroundPickerSheet extends StatelessWidget {
  const LiveBackgroundPickerSheet({
    super.key,
    required this.selectedUrl,
    required this.onSelectUrl,
    required this.onSelectFile,
  });

  final String? selectedUrl;
  final ValueChanged<String?> onSelectUrl;
  final ValueChanged<String> onSelectFile;

  static const presets = [
  (
    'Mor gradient',
    'https://canlifal.com/apple-touch-icon.png',
  ),
  (
    'Koyu gece',
    'https://images.unsplash.com/photo-1614850523459-c9f4c5c1df66?w=800&q=80',
  ),
  (
    'Neon şehir',
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=80',
  ),
  (
    'Stüdyo',
    'https://images.unsplash.com/photo-1598488035139-bdbb2231bb04?w=800&q=80',
  ),
];

  static Future<void> show(
    BuildContext context, {
    required String? selectedUrl,
    required ValueChanged<String?> onSelectUrl,
    required ValueChanged<String> onSelectFile,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12081F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => LiveBackgroundPickerSheet(
        selectedUrl: selectedUrl,
        onSelectUrl: onSelectUrl,
        onSelectFile: onSelectFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Arka plan seç',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Hazır görseller veya galeriden kendi arka planınız',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: presets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final p = presets[i];
                  final selected = selectedUrl == p.$2;
                  return GestureDetector(
                    onTap: () {
                      onSelectUrl(p.$2);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFB832FF)
                              : Colors.white24,
                          width: selected ? 2 : 1,
                        ),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(p.$2),
                          fit: BoxFit.cover,
                          onError: (_, _) {},
                        ),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          p.$1,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final file = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (file == null) return;
                onSelectFile(file.path);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Galeriden seç'),
            ),
            TextButton(
              onPressed: () {
                onSelectUrl(null);
                Navigator.pop(context);
              },
              child: const Text('Arka planı kaldır'),
            ),
          ],
        ),
      ),
    );
  }
}
