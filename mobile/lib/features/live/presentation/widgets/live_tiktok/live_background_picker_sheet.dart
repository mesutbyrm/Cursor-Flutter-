import 'dart:io';

import 'package:canlifal_social/core/media/cloud_upload_service.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/network/dio_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Hazır yayın arka planı — uygulamadaki mistik görseller (yerel asset).
class LiveBackgroundPreset {
  const LiveBackgroundPreset(this.label, this.asset);

  final String label;
  final String asset;
}

/// Yayın arka planı — hazır görseller + galeri.
///
/// Hazır görseller yerel asset'tir; seçilince bir kez siteye yüklenir ve dönen
/// URL kullanılır (izleyiciler de görür). Aynı oturumda tekrar yüklenmez.
class LiveBackgroundPickerSheet extends ConsumerStatefulWidget {
  const LiveBackgroundPickerSheet({
    super.key,
    required this.selectedUrl,
    required this.onSelectUrl,
    required this.onSelectFile,
  });

  final String? selectedUrl;
  final ValueChanged<String?> onSelectUrl;
  final ValueChanged<String> onSelectFile;

  static const presets = <LiveBackgroundPreset>[
    LiveBackgroundPreset('Mistik gece', 'assets/backgrounds/login-night-sky.webp'),
    LiveBackgroundPreset('Kristal küre', 'assets/fortune/gunluk-fal.webp'),
    LiveBackgroundPreset('Altın taç', 'assets/membership/gold.webp'),
    LiveBackgroundPreset('Kozmik harita', 'assets/fortune/dogum-haritasi.webp'),
  ];

  /// asset → yüklenmiş URL (oturum boyunca).
  static final _uploaded = <String, String>{};

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
  ConsumerState<LiveBackgroundPickerSheet> createState() =>
      _LiveBackgroundPickerSheetState();
}

class _LiveBackgroundPickerSheetState
    extends ConsumerState<LiveBackgroundPickerSheet> {
  String? _busyAsset;

  Future<void> _pickPreset(LiveBackgroundPreset p) async {
    if (_busyAsset != null) return;
    final cached = LiveBackgroundPickerSheet._uploaded[p.asset];
    if (cached != null) {
      widget.onSelectUrl(cached);
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _busyAsset = p.asset);
    try {
      final data = await rootBundle.load(p.asset);
      final dir = await getTemporaryDirectory();
      final name = p.asset.split('/').last;
      final file = File('${dir.path}${Platform.pathSeparator}live_bg_$name');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      final url = await CloudMediaUploadService(ref.read(dioProvider))
          .uploadImageFile(
        file,
        folder: 'live-backgrounds',
        isPublic: true,
        requireSiteOrigin: true,
      );
      LiveBackgroundPickerSheet._uploaded[p.asset] = url;
      widget.onSelectUrl(url);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyAsset = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = LiveBackgroundPickerSheet.presets;
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
                  final uploaded = LiveBackgroundPickerSheet._uploaded[p.asset];
                  final selected =
                      uploaded != null && widget.selectedUrl == uploaded;
                  final busy = _busyAsset == p.asset;
                  return Semantics(
                    button: true,
                    label: '${p.label} arka planı',
                    child: GestureDetector(
                      onTap: () => _pickPreset(p),
                      child: Container(
                        width: 88,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFB832FF)
                                : Colors.white24,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              p.asset,
                              fit: BoxFit.cover,
                              cacheWidth: 240,
                              errorBuilder: (_, _, _) =>
                                  const ColoredBox(color: Color(0xFF1A0F32)),
                            ),
                            if (busy)
                              const ColoredBox(
                                color: Color(0x99000000),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.black.withValues(alpha: 0.55),
                                child: Text(
                                  p.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busyAsset != null
                  ? null
                  : () async {
                      final file = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (file == null) return;
                      widget.onSelectFile(file.path);
                      if (context.mounted) Navigator.pop(context);
                    },
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Galeriden seç'),
            ),
            TextButton(
              onPressed: _busyAsset != null
                  ? null
                  : () {
                      widget.onSelectUrl(null);
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
