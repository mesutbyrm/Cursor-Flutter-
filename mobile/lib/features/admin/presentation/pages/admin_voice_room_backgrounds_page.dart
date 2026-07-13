import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/core/media/cloud_upload_service.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/network/dio_provider.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../voice_hub/presentation/providers/chat_room_providers.dart';
import '../providers/staff_access_provider.dart';

/// Admin — sohbet odası arka plan kataloğu (R2/S3 yükleme).
class AdminVoiceRoomBackgroundsPage extends ConsumerStatefulWidget {
  const AdminVoiceRoomBackgroundsPage({super.key});

  @override
  ConsumerState<AdminVoiceRoomBackgroundsPage> createState() =>
      _AdminVoiceRoomBackgroundsPageState();
}

class _AdminVoiceRoomBackgroundsPageState
    extends ConsumerState<AdminVoiceRoomBackgroundsPage> {
  var _loading = true;
  var _uploading = false;
  List<String> _backgrounds = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final urls =
          await ref.read(chatRoomRemoteProvider).fetchBackgrounds();
      if (mounted) {
        setState(() {
          _backgrounds = urls;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiException.userMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _uploadFromGallery() async {
    if (_uploading) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _uploadFile(File(picked.path));
  }

  Future<void> _uploadFile(File file) async {
    setState(() => _uploading = true);
    try {
      final uploader = CloudMediaUploadService(ref.read(dioProvider));
      final url = await uploader.uploadImageFile(
        file,
        folder: 'voice-room-backgrounds',
        isPublic: true,
        requireSiteOrigin: true,
      );
      try {
        await ref.read(chatRoomRemoteProvider).registerVoiceRoomBackground(url);
      } catch (_) {
        // Katalog API henüz yoksa yükleme yine de CDN'de kalır.
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arka plan yüklendi')),
      );
      await _load();
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
    final access = ref.watch(staffAccessProvider);
    if (!access.isSiteAdmin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Bu alan yalnızca admin veya yönetici hesapları içindir.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Sohbet odası görselleri',
                      subtitle: 'R2/S3 — tüm odalarda seçilebilir katalog',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _loading ? null : () { _load(); },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: FilledButton.icon(
                onPressed: _uploading ? null : _uploadFromGallery,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(_uploading ? 'Yükleniyor…' : 'Görsel yükle (S3)'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppThemeColors.accentPurple,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _backgrounds.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 80),
                                    Center(
                                      child: Text(
                                        'Henüz arka plan yok — yukarıdan yükleyin.',
                                      ),
                                    ),
                                  ],
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 0.72,
                                  ),
                                  itemCount: _backgrounds.length,
                                  itemBuilder: (_, i) {
                                    final url = _backgrounds[i];
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CanlifalNetworkImage(
                                        url: url,
                                        fit: BoxFit.cover,
                                        thumbnailWidth: 360,
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
