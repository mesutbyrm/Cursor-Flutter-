import 'dart:io';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/media/cloud_upload_service.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_ui_provider.dart';
import '../theme/voice_room_tokens.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';
import 'voice_room_management_panel.dart';
import 'voice_room_commands_panel.dart';
import 'voice_room_sheets.dart';

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

Future<void> showVoiceRoomHubSettingsSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required bool isOwner,
  void Function(ChatRoomPresence user)? onUserTap,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _HubSettingsSheet(
      room: room,
      live: live,
      perms: perms,
      isOwner: isOwner,
      onUserTap: onUserTap,
    ),
  );
}

class _HubSettingsSheet extends ConsumerStatefulWidget {
  const _HubSettingsSheet({
    required this.room,
    required this.live,
    required this.perms,
    required this.isOwner,
    this.onUserTap,
  });

  final VoiceRoomEntity room;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final void Function(ChatRoomPresence user)? onUserTap;

  @override
  ConsumerState<_HubSettingsSheet> createState() => _HubSettingsSheetState();
}

class _HubSettingsSheetState extends ConsumerState<_HubSettingsSheet> {
  List<String> _backgrounds = const [];
  var _loadingBg = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBackgrounds());
  }

  Future<void> _loadBackgrounds() async {
    if (_loadingBg || _backgrounds.isNotEmpty) return;
    setState(() => _loadingBg = true);
    try {
      final urls = await ref
          .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
          .fetchBackgrounds();
      if (mounted) setState(() => _backgrounds = urls);
    } finally {
      if (mounted) setState(() => _loadingBg = false);
    }
  }

  Future<void> _changeNickname() async {
    final controller = TextEditingController();
    try {
      final err = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Oda rumuzu'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Sohbette görünecek rumuz',
              border: OutlineInputBorder(),
            ),
            maxLength: 32,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
      if (!mounted || err == null) return;
      final message = await ref
          .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
          .updateRoomNickname(err);
      if (!mounted) return;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rumuz güncellendi')),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  void _openRoomCommands() {
    Navigator.pop(context);
    showVoiceRoomCommandsPanel(
      context,
      ref,
      room: widget.room,
      perms: widget.perms,
      isOwner: widget.isOwner,
    );
  }

  Future<void> _applyBackground(String url) async {
    final err = await ref
        .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
        .setRoomBackground(url);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Arka plan güncellendi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(voiceRoomUiProvider);
    final canBg = widget.perms.canChangeBackground || widget.isOwner;

    final tiles = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.settings_rounded,
        label: 'Oda yönetimi',
        onTap: () {
          Navigator.pop(context);
          showVoiceRoomManagementPanel(
            context,
            ref,
            room: widget.room,
            live: widget.live,
            perms: widget.perms,
            isOwner: widget.isOwner,
            onUserTap: widget.onUserTap,
          );
        },
      ),
      (
        icon: Icons.badge_rounded,
        label: 'Rumuz',
        onTap: _changeNickname,
      ),
      (
        icon: Icons.terminal_rounded,
        label: 'Komutlar',
        onTap: _openRoomCommands,
      ),
      (
        icon: Icons.people_rounded,
        label: 'Dinleyici listesi',
        onTap: () {
          Navigator.pop(context);
          showVoiceSpeakerListSheet(
            context,
            presence: widget.live.presence,
            room: widget.room,
            onUserTap: widget.onUserTap,
          );
        },
      ),
      if (canBg)
        (
          icon: Icons.wallpaper_rounded,
          label: 'Arka plan',
          onTap: () {
            Navigator.pop(context);
            showVoiceRoomBackgroundSheet(context, ref, room: widget.room);
          },
        ),
      (
        icon: ui.headphonesOn
            ? Icons.headset_rounded
            : Icons.headset_off_rounded,
        label: 'Hoparlör',
        onTap: () =>
            ref.read(voiceRoomUiProvider.notifier).toggleHeadphones(),
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scroll) => VoiceGlass(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
        child: ListView(
          controller: scroll,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.92,
              ),
              itemCount: tiles.length,
              itemBuilder: (context, i) {
                final t = tiles[i];
                return Tooltip(
                  message: t.label,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: t.onTap,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          t.icon,
                          color: VoiceRoomTokens.neonBlue,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (canBg && _loadingBg)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (canBg && _backgrounds.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _backgrounds.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final url = _backgrounds[i];
                    return GestureDetector(
                      onTap: () => _applyBackground(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CanlifalNetworkImage(
                          url: url,
                          width: 160,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
    final canUpload = ref.watch(staffAccessProvider).isSiteAdmin;
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
                  ? 'Hazır arka planlardan seçin veya yükleyin.'
                  : 'Admin tarafından yüklenen arka planlardan seçin.',
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
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
