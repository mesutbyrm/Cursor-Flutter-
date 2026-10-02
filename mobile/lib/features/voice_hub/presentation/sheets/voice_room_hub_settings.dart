import 'dart:io';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/media/cloud_upload_service.dart';
import 'package:canlifal_social/core/performance/list_perf.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/membership/membership_capability_providers.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/voice_room_background_policy.dart';
import '../providers/chat_room_providers.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../widgets/premium/voice_glass.dart';

Future<void> showVoiceRoomBackgroundSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Modal zaten kök ProviderScope altında; nested ProviderScope +
    // containerOf(context) gereksizdi ve pop sonrası defunct context'te
    // "No ProviderScope found" hatası veriyordu.
    builder: (ctx) => _VoiceRoomBackgroundSheet(room: room),
  );
}

class _VoiceRoomBackgroundSheet extends ConsumerStatefulWidget {
  const _VoiceRoomBackgroundSheet({required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<_VoiceRoomBackgroundSheet> createState() =>
      _VoiceRoomBackgroundSheetState();
}

class _VoiceRoomBackgroundSheetState
    extends ConsumerState<_VoiceRoomBackgroundSheet> {
  var _uploading = false;
  List<String> _presets = const [];
  var _loadingPresets = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPresets());
  }

  Future<void> _loadPresets() async {
    if (_loadingPresets) return;
    setState(() => _loadingPresets = true);
    try {
      final urls = await ref
          .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
          .fetchBackgrounds();
      if (mounted) setState(() => _presets = urls);
    } finally {
      if (mounted) setState(() => _loadingPresets = false);
    }
  }

  Future<void> _applyPreset(String url) async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final err = await ref
          .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
          .setRoomBackground(url);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Arka plan güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String> _uploadFile(File file) async {
    final uploader = CloudMediaUploadService(ref.read(dioProvider));
    return uploader.uploadImageFile(
      file,
      folder: 'voice-room-backgrounds',
      isPublic: true,
      requireSiteOrigin: true,
    );
  }

  Future<void> _pickFromCamera() async {
    if (_uploading) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _applyUploadedFile(File(picked.path));
  }

  Future<void> _pickFromGallery() async {
    if (_uploading) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _applyUploadedFile(File(picked.path));
  }

  Future<void> _applyUploadedFile(File file) async {
    setState(() => _uploading = true);
    try {
      final url = await _uploadFile(file);
      final err = await ref
          .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
          .setRoomBackground(url);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Arka plan güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Kendi arka planını yükleme: site admin veya Gold+ üyelik.
    final isAdmin = ref.watch(staffAccessProvider).isSiteAdmin;
    final tier = ref.watch(membershipCapabilitiesSyncProvider).effectiveTier;
    final canUpload = isAdmin || tier.isAtLeast(VipTier.gold);
    if (!voiceRoomBackgroundUnlocked(widget.room, isSiteAdmin: isAdmin)) {
      return VoiceGlass(
        borderRadius: 24,
        padding: EdgeInsets.fromLTRB(16, 20, 16, bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 32),
            const SizedBox(height: 10),
            const Text(
              'Oda arka planı kilitli',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              voiceRoomBackgroundLockedMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.onSurfaceMuted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scroll) => VoiceGlass(
        borderRadius: 24,
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
        child: ListView(
          controller: scroll,
          children: [
            const Text(
              'Oda arka planı',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              canUpload
                  ? 'Hazır arka planlardan seçin veya kendi görselinizi yükleyin.'
                  : 'Hazır arka planlardan seçin. Kendi görselinizi yüklemek için Gold üyelik gerekir.',
              style: TextStyle(
                color: context.colors.onSurfaceMuted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (_loadingPresets)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_presets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Arka plan listesi yüklenemedi. Tekrar deneyin.',
                  style: TextStyle(color: context.colors.onSurfaceMuted),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_presets.isNotEmpty) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const crossAxisCount = 3;
                  const spacing = 8.0;
                  const aspect = 0.75;
                  final gridHeight = ListPerf.nestedGridHeight(
                    itemCount: _presets.length,
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: aspect,
                    crossAxisExtent: constraints.maxWidth,
                  );
                  return SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: aspect,
                      ),
                      itemCount: _presets.length,
                      itemBuilder: (_, i) {
                        final url = _presets[i];
                        return GestureDetector(
                          onTap: _uploading ? null : () => _applyPreset(url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CanlifalNetworkImage(
                              url: url,
                              thumbnailWidth: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
            if (canUpload) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickFromCamera,
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Kamera'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _uploading ? null : _pickFromGallery,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_rounded),
                label: Text(_uploading ? 'Yükleniyor…' : 'Galeriden seç'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
