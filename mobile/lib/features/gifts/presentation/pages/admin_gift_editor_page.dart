import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_http_cache.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../data/admin_gift_media_probe.dart';
import '../../domain/admin_gift_dto_mapper.dart';
import '../../domain/admin_gift_type.dart';
import '../providers/admin_gift_providers.dart';
import '../providers/gift_catalog_invalidate.dart';
import '../widgets/admin_gift_media_preview.dart';

/// Tam özellikli hediye oluşturma / düzenleme ekranı.
class AdminGiftEditorPage extends ConsumerStatefulWidget {
  const AdminGiftEditorPage({super.key, this.gift});

  final AdminGiftType? gift;

  @override
  ConsumerState<AdminGiftEditorPage> createState() =>
      _AdminGiftEditorPageState();
}

class _AdminGiftEditorPageState extends ConsumerState<AdminGiftEditorPage> {
  late final TextEditingController _nameTr;
  late final TextEditingController _nameEn;
  late final TextEditingController _price;
  late final TextEditingController _icon;
  late final TextEditingController _category;
  late final TextEditingController _tier;
  late final TextEditingController _durationMs;
  late final TextEditingController _effectColor;
  late final TextEditingController _sortOrder;

  String? _imageUrl;
  String? _thumbnailUrl;
  String? _animationUrl;
  String? _soundUrl;
  String? _imageCloudPath;
  String? _thumbnailCloudPath;
  String? _animationCloudPath;
  String? _soundCloudPath;
  bool _imageChanged = false;
  bool _thumbnailChanged = false;
  bool _animationChanged = false;
  bool _soundChanged = false;
  String _animationType = 'image';
  bool _comboEnabled = false;
  bool _isPremium = false;
  bool _isFullscreen = false;
  bool _isActive = true;
  bool _isHidden = false;
  bool _isFeatured = false;
  bool _isPopular = false;
  bool _isNew = false;
  bool _isLucky = false;
  bool _saving = false;
  String? _uploadingKind;

  bool get _isEdit => widget.gift != null;

  @override
  void initState() {
    super.initState();
    final g = widget.gift;
    _nameTr = TextEditingController(text: g?.name ?? '');
    _nameEn = TextEditingController(text: g?.nameEn ?? '');
    _price = TextEditingController(text: g != null ? '${g.price}' : '');
    _icon = TextEditingController(text: g?.icon ?? '');
    _category = TextEditingController(text: g?.category ?? '');
    _tier = TextEditingController(text: g?.tier ?? '');
    _durationMs = TextEditingController(
      text: g != null && g.animationDurationMs > 0
          ? '${g.animationDurationMs}'
          : '',
    );
    _effectColor = TextEditingController(text: g?.effectColor ?? '');
    _sortOrder = TextEditingController(
      text: g != null && g.sortOrder > 0 ? '${g.sortOrder}' : '',
    );
    _imageUrl = g?.imageUrl;
    _thumbnailUrl = g?.thumbnailUrl;
    _animationUrl = g?.animationUrl;
    _soundUrl = g?.soundUrl;
    _animationType = g?.animationType ?? 'image';
    _isPremium = g?.isPremium ?? false;
    _isFullscreen = g?.isFullscreen ?? false;
    _isActive = g?.isActive ?? true;
    _comboEnabled = g?.comboEnabled ?? false;
    _isHidden = g?.isHidden ?? false;
    _isFeatured = g?.isFeatured ?? false;
    _isPopular = g?.isPopular ?? false;
    _isNew = g?.isNew ?? false;
    _isLucky = g?.isLucky ?? false;
  }

  @override
  void dispose() {
    _nameTr.dispose();
    _nameEn.dispose();
    _price.dispose();
    _icon.dispose();
    _category.dispose();
    _tier.dispose();
    _durationMs.dispose();
    _effectColor.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  Future<void> _uploadFile({
    required String kind,
    List<String>? extensions,
    bool useGallery = false,
  }) async {
    setState(() => _uploadingKind = kind);
    try {
      File? file;
      if (useGallery) {
        final img = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (img != null) file = File(img.path);
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: extensions != null ? FileType.custom : FileType.any,
          allowedExtensions: extensions,
          withData: false,
        );
        final path = result?.files.single.path;
        if (path != null) file = File(path);
      }
      if (file == null) return;

      final uploaded = await ref
          .read(adminGiftRemoteProvider)
          .uploadAsset(file, kind: kind);
      if (!mounted) return;
      final isVideo = _guessAnimationType(file.path) == 'video';
      if (kind == 'asset' && isVideo) {
        final ms = await AdminGiftMediaProbe.durationMs(file);
        if (ms != null && ms > 0) {
          _durationMs.text = '$ms';
        }
        final needsThumb = _imageCloudPath == null &&
            (!_isEdit || !_imageChanged || (_imageUrl?.trim().isEmpty ?? true));
        if (needsThumb) {
          final thumb = await AdminGiftMediaProbe.thumbnailFile(file);
          if (thumb != null) {
            try {
              final thumbUp = await ref
                  .read(adminGiftRemoteProvider)
                  .uploadAsset(thumb, kind: 'icon');
              if (mounted) {
                setState(() {
                  _imageUrl = thumbUp.previewUrl;
                  _imageCloudPath = thumbUp.cloudPath;
                  _imageChanged = true;
                });
              }
            } catch (_) {
              // Önizleme isteğe bağlı; animasyon yüklemesi başarılı kalsın.
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {
        // Backend upload-url yalnızca icon/thumbnail/asset/sound kabul ediyor.
        switch (kind) {
          case 'icon':
            _imageUrl = uploaded.previewUrl;
            _imageCloudPath = uploaded.cloudPath;
            _imageChanged = true;
          case 'thumbnail':
            _thumbnailUrl = uploaded.previewUrl;
            _thumbnailCloudPath = uploaded.cloudPath;
            _thumbnailChanged = true;
          case 'asset':
            _animationUrl = uploaded.previewUrl;
            _animationCloudPath = uploaded.cloudPath;
            _animationChanged = true;
            _animationType = _guessAnimationType(file!.path);
          case 'sound':
            _soundUrl = uploaded.previewUrl;
            _soundCloudPath = uploaded.cloudPath;
            _soundChanged = true;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _uploadingKind = null);
    }
  }

  String _guessAnimationType(String path) {
    final f = path.toLowerCase();
    if (f.endsWith('.json')) return 'lottie';
    if (f.endsWith('.svga')) return 'svga';
    if (f.endsWith('.mp4') || f.endsWith('.webm') || f.endsWith('.mov')) {
      return 'video';
    }
    if (f.endsWith('.gif')) return 'gif';
    if (f.endsWith('.png') ||
        f.endsWith('.jpg') ||
        f.endsWith('.jpeg') ||
        f.endsWith('.webp')) {
      return 'image';
    }
    return _animationType;
  }

  Future<void> _save() async {
    if (_saving) return;
    final access = ref.read(staffAccessProvider);
    if (!access.canManageGifts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hediye ekleme yalnızca admin veya kurucu (yonetici) hesabına açıktır.',
          ),
        ),
      );
      return;
    }
    if (_uploadingKind != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dosya yüklemesi tamamlanmadan kaydedilemez.'),
        ),
      );
      return;
    }
    final name = _nameTr.text.trim();
    final price = int.tryParse(_price.text.trim());
    if (name.isEmpty || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Türkçe isim ve geçerli jeton fiyatı gerekli.'),
        ),
      );
      return;
    }
    final duration = int.tryParse(_durationMs.text.trim());
    final color = _effectColor.text.trim();
    final hasAnimationMedia =
        _animationCloudPath != null ||
        (_isEdit &&
            !_animationChanged &&
            ((widget.gift?.cloudStoragePath?.trim().isNotEmpty ?? false) ||
                (_animationUrl?.trim().isNotEmpty ?? false)));
    final sortOrder = int.tryParse(_sortOrder.text.trim());
    setState(() => _saving = true);
    final body = _isEdit
        ? AdminGiftDtoMapper.updateBody(
            name: name,
            nameEn: _nameEn.text.trim().isEmpty ? name : _nameEn.text.trim(),
            price: price,
            icon: _icon.text.trim().isNotEmpty ? _icon.text.trim() : null,
            category:
                _category.text.trim().isNotEmpty ? _category.text.trim() : null,
            tier: _tier.text.trim().isNotEmpty ? _tier.text.trim() : null,
            sortOrder: sortOrder,
            iconChanged: _imageChanged,
            iconImageCloudPath: _imageCloudPath,
            iconImageUrl: _imageUrl,
            thumbnailChanged: _thumbnailChanged,
            thumbnailCloudPath: _thumbnailCloudPath,
            thumbnailUrl: _thumbnailUrl,
            assetChanged: _animationChanged,
            cloudStoragePath: _animationCloudPath,
            assetUrl: _animationUrl,
            assetType: hasAnimationMedia ? _animationType : 'image',
            hasExistingAsset: widget.gift?.cloudStoragePath?.isNotEmpty == true ||
                widget.gift?.animationUrl?.isNotEmpty == true,
            soundChanged: _soundChanged,
            soundCloudPath: _soundCloudPath,
            soundUrl: _soundUrl,
            animationDurationMs: duration,
            effectColor: color.isNotEmpty ? color : null,
            comboEnabled: _comboEnabled,
            isPremium: _isPremium,
            isFullscreen: _isFullscreen,
            isActive: _isActive,
            isHidden: _isHidden,
            isFeatured: _isFeatured,
            isPopular: _isPopular,
            isNew: _isNew,
            isLucky: _isLucky,
          )
        : AdminGiftDtoMapper.createBody(
            name: name,
            nameEn: _nameEn.text.trim().isEmpty ? name : _nameEn.text.trim(),
            price: price,
            icon: _icon.text.trim().isNotEmpty ? _icon.text.trim() : null,
            category:
                _category.text.trim().isNotEmpty ? _category.text.trim() : null,
            tier: _tier.text.trim().isNotEmpty ? _tier.text.trim() : null,
            sortOrder: sortOrder,
            iconImageCloudPath: _imageCloudPath,
            iconImageUrl: _imageUrl,
            thumbnailCloudPath: _thumbnailCloudPath,
            thumbnailUrl: _thumbnailUrl,
            cloudStoragePath:
                hasAnimationMedia ? _animationCloudPath : null,
            assetUrl: hasAnimationMedia ? _animationUrl : null,
            assetType: hasAnimationMedia ? _animationType : 'image',
            soundCloudPath: _soundCloudPath,
            soundUrl: _soundUrl,
            animationDurationMs: duration,
            effectColor: color.isNotEmpty ? color : null,
            comboEnabled: _comboEnabled,
            isPremium: _isPremium,
            isFullscreen: _isFullscreen,
            isActive: _isActive,
            isHidden: _isHidden,
            isFeatured: _isFeatured,
            isPopular: _isPopular,
            isNew: _isNew,
            isLucky: _isLucky,
          );
    try {
      // Cüzdan yenilemesi kaydı engellemesin — zaman aşımında arka planda dene.
      unawaited(
        ref.read(walletBalancesProvider.notifier).refresh(force: true).catchError(
          (_) => WalletBalances.empty,
        ),
      );
      final remote = ref.read(adminGiftRemoteProvider);
      AdminGiftType? saved;
      if (_isEdit) {
        saved = await remote.updateGift(widget.gift!.id, body);
      } else {
        saved = await remote.createGift(body);
      }
      if (saved != null) _verifySavedAssets(saved);

      // GET katalog cache'lerini temizle; aksi halde provider invalidate edilse
      // bile yeni hediye 15–60 sn eski disk/memory cache'inden okunabiliyordu.
      await Future.wait([
        ApiHttpCache.invalidatePath('/api/video-streams/gifts'),
        ApiHttpCache.invalidatePath(ApiEndpoints.giftsTypes),
        ApiHttpCache.invalidatePath('/api/gifts/catalog'),
        ApiHttpCache.invalidatePath('/api/gifts/version'),
      ]);
      await invalidateAllGiftCatalogs(ref);
      ref.invalidate(adminGiftListProvider);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _verifySavedAssets(AdminGiftType saved) {
    bool missing(String? uploadedPath, String? savedPath) {
      if (uploadedPath == null || uploadedPath.isEmpty) return false;
      if (savedPath == null || savedPath.isEmpty) return true;
      final uploaded = uploadedPath.trim();
      final savedValue = savedPath.trim();
      if (savedValue == uploaded) return false;
      if (savedValue.endsWith(uploaded) || uploaded.endsWith(savedValue)) {
        return false;
      }
      return true;
    }

    if (missing(_imageCloudPath, saved.iconImageCloudPath) ||
        missing(_thumbnailCloudPath, saved.thumbnailCloudPath) ||
        missing(_animationCloudPath, saved.cloudStoragePath) ||
        missing(_soundCloudPath, saved.soundCloudPath)) {
      throw const ApiException(
        'Hediye kaydı oluştu ancak yüklenen medya yolu kayda yazılmadı.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageGifts) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0524),
        appBar: AppBar(
          backgroundColor: const Color(0xFF12082A),
          title: Text(_isEdit ? 'Hediyeyi Düzenle' : 'Hediye Ekle'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Hediye eklemek için admin veya kurucu (yonetici) hesabıyla giriş yapın.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0x99FFFFFF)),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: Text(_isEdit ? 'Hediyeyi Düzenle' : 'Hediye Ekle'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Kaydet',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _sectionTitle('Görseller & Medya'),
          _uploadTile(
            label: 'Görsel (PNG / WebP)',
            hint: 'Panelde görünen statik ikon',
            url: _imageUrl,
            kind: 'icon',
            uploading: _uploadingKind == 'icon',
            onPickGallery: () => _uploadFile(
              kind: 'icon',
              extensions: ['png', 'webp', 'jpg', 'jpeg'],
              useGallery: true,
            ),
            onPickFile: () => _uploadFile(
              kind: 'icon',
              extensions: ['png', 'webp', 'jpg', 'jpeg'],
            ),
          ),
          _uploadTile(
            label: 'Thumbnail',
            hint: 'Liste ve küçük önizleme',
            url: _thumbnailUrl,
            kind: 'thumbnail',
            uploading: _uploadingKind == 'thumbnail',
            onPickGallery: () => _uploadFile(
              kind: 'thumbnail',
              extensions: ['png', 'webp', 'jpg'],
              useGallery: true,
            ),
            onPickFile: () => _uploadFile(
              kind: 'thumbnail',
              extensions: ['png', 'webp', 'jpg'],
            ),
          ),
          _uploadTile(
            label: 'Animasyon',
            hint: 'MP4 · WebM · SVGA · Lottie · GIF',
            url: _animationUrl,
            kind: 'asset',
            uploading: _uploadingKind == 'asset',
            animationType: _animationType,
            onPickFile: () => _uploadFile(
              kind: 'asset',
              extensions: ['mp4', 'webm', 'mov', 'svga', 'json', 'gif'],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: AdminGiftAnimationTypes.all
                      .any((e) => e.$1 == _animationType)
                  ? _animationType
                  : 'image',
              dropdownColor: const Color(0xFF1A1030),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Animasyon türü'),
              items: [
                for (final t in AdminGiftAnimationTypes.all)
                  DropdownMenuItem(value: t.$1, child: Text(t.$2)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _animationType = v);
              },
            ),
          ),
          _uploadTile(
            label: 'Ses dosyası (MP3 / WAV)',
            hint: 'Hediye SFX',
            url: _soundUrl,
            kind: 'sound',
            uploading: _uploadingKind == 'sound',
            isAudio: true,
            onPickFile: () =>
                _uploadFile(kind: 'sound', extensions: ['mp3', 'wav', 'm4a']),
          ),
          const SizedBox(height: 8),
          _sectionTitle('Temel Bilgiler'),
          _field(_nameTr, 'Türkçe isim *'),
          _field(_nameEn, 'İngilizce isim'),
          _field(_price, 'Jeton fiyatı *', number: true),
          _field(_icon, 'İkon (emoji yedek, ör. 💎)'),
          _chipField(
            controller: _category,
            label: 'Kategori',
            presets: AdminGiftPresets.categories,
          ),
          _chipField(
            controller: _tier,
            label: 'Kademe',
            presets: AdminGiftPresets.tiers,
          ),
          const SizedBox(height: 8),
          _sectionTitle('Animasyon & Efekt'),
          _field(_durationMs, 'Animasyon süresi (ms)', number: true),
          _field(_effectColor, 'Efekt rengi (hex, ör. #FF6B6B)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in const [
                '#FF6B6B',
                '#FFD54F',
                '#7C3AED',
                '#3D7BFF',
                '#66E36F',
                '#FF3D77',
              ])
                ActionChip(
                  label: Text(c, style: const TextStyle(fontSize: 11)),
                  backgroundColor: _parseColor(c).withValues(alpha: 0.35),
                  onPressed: () => setState(() => _effectColor.text = c),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle('Davranış'),
          _switchTile(
            'Premium hediye',
            _isPremium,
            (v) => setState(() => _isPremium = v),
          ),
          _switchTile(
            'Tam ekran animasyon',
            _isFullscreen,
            (v) => setState(() => _isFullscreen = v),
          ),
          _switchTile(
            'Kombo (combo)',
            _comboEnabled,
            (v) => setState(() => _comboEnabled = v),
          ),
          _switchTile('Yeni rozeti', _isNew, (v) => setState(() => _isNew = v)),
          _switchTile(
            '🍀 Şanslı hediye',
            _isLucky,
            (v) => setState(() => _isLucky = v),
          ),
          _switchTile('Öne çıkan', _isFeatured, (v) => setState(() => _isFeatured = v)),
          _switchTile('Popüler', _isPopular, (v) => setState(() => _isPopular = v)),
          _switchTile('Gizli', _isHidden, (v) => setState(() => _isHidden = v)),
          _field(_sortOrder, 'Sıralama (sortOrder)', number: true),
          _switchTile(
            'Durum: Aktif',
            _isActive,
            (v) => setState(() => _isActive = v),
            subtitle: _isActive ? 'Katalogda görünür' : 'Pasif — gizli',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
              ),
              child: Text(_isEdit ? 'Değişiklikleri Kaydet' : 'Hediye Ekle'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Text(
      t,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 15,
      ),
    ),
  );

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        inputFormatters: number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDeco(label),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0x99FFFFFF)),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color(0x33FFFFFF)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF7C3AED)),
    ),
  );

  Widget _chipField({
    required TextEditingController controller,
    required String label,
    required List<String> presets,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(controller, label),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final p in presets)
              ActionChip(
                label: Text(p, style: const TextStyle(fontSize: 11)),
                onPressed: () => setState(() => controller.text = p),
              ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _switchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
            )
          : null,
      value: value,
      activeThumbColor: const Color(0xFF66E36F),
      onChanged: onChanged,
    );
  }

  Widget _uploadTile({
    required String label,
    required String hint,
    required String? url,
    required String kind,
    required bool uploading,
    VoidCallback? onPickGallery,
    VoidCallback? onPickFile,
    bool isAudio = false,
    String? animationType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0E0524),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: uploading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AdminGiftMediaPreview(
                      url: url,
                      size: 56,
                      isAudio: isAudio,
                      animationType: animationType,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  hint,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 11,
                  ),
                ),
                if (url != null)
                  Text(
                    url.length > 42
                        ? '…${url.substring(url.length - 38)}'
                        : url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0x66FFFFFF),
                      fontSize: 9,
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    if (onPickGallery != null)
                      _miniBtn('Galeri', onPickGallery, disabled: uploading),
                    if (onPickFile != null)
                      _miniBtn('Dosya', onPickFile, disabled: uploading),
                    if (url != null)
                      _miniBtn('Kaldır', () {
                        setState(() {
                          switch (kind) {
                            case 'icon':
                              _imageUrl = null;
                              _imageCloudPath = null;
                              _imageChanged = true;
                            case 'thumbnail':
                              _thumbnailUrl = null;
                              _thumbnailCloudPath = null;
                              _thumbnailChanged = true;
                            case 'asset':
                              _animationUrl = null;
                              _animationCloudPath = null;
                              _animationChanged = true;
                            case 'sound':
                              _soundUrl = null;
                              _soundCloudPath = null;
                              _soundChanged = true;
                          }
                        });
                      }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(String label, VoidCallback onTap, {bool disabled = false}) {
    return OutlinedButton(
      onPressed: disabled ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        side: const BorderSide(color: Color(0x44FFFFFF)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Color _parseColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    if (v == null) return const Color(0xFF7C3AED);
    return Color(v);
  }
}
