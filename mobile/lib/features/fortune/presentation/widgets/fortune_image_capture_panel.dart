import 'dart:io';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/fortune_type_entity.dart';
import '../data/fortune_image_capture_config.dart';
import 'fortune_glass_card.dart';

export '../data/fortune_image_capture_config.dart';

/// Kahve fincanı / el falı — kamera veya galeriden görsel yükleme paneli.
class FortuneImageCapturePanel extends StatefulWidget {
  const FortuneImageCapturePanel({
    super.key,
    required this.type,
    required this.onChanged,
    this.initial,
  });

  final FortuneTypeEntity type;
  final ValueChanged<FortuneLocalImageInput> onChanged;
  final FortuneLocalImageInput? initial;

  @override
  State<FortuneImageCapturePanel> createState() =>
      _FortuneImageCapturePanelState();
}

class _FortuneImageCapturePanelState extends State<FortuneImageCapturePanel> {
  final _picker = ImagePicker();
  String? _cupPath;
  String? _saucerPath;
  String? _palmPath;
  var _hand = 'right';

  FortuneTypeEntity get type => widget.type;
  bool get _isCoffee => FortuneImageCaptureConfig.isCoffee(type);
  bool get _isPalm => FortuneImageCaptureConfig.isPalm(type);

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _cupPath = init.cupPath;
      _saucerPath = init.saucerPath;
      _palmPath = init.palmPath;
      _hand = init.hand;
    }
  }

  FortuneLocalImageInput get _input => FortuneLocalImageInput(
        cupPath: _cupPath,
        saucerPath: _saucerPath,
        palmPath: _palmPath,
        hand: _hand,
      );

  void _emit() => widget.onChanged(_input);

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _pick({
    required ImageSource source,
    required void Function(String path) onPicked,
  }) async {
    if (source == ImageSource.camera) {
      final ok = await _ensureCameraPermission();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera izni gerekli')),
        );
        return;
      }
    }
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (file == null || !mounted) return;
      onPicked(file.path);
      _emit();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel seçilemedi: $e')),
      );
    }
  }

  Future<void> _showSourceSheet(String slot) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF140A28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
              const SizedBox(height: 16),
              Text(
                slot == 'cup'
                    ? 'Fincan içi fotoğrafı'
                    : slot == 'saucer'
                    ? 'Tabak fotoğrafı'
                    : 'El fotoğrafı',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_camera_rounded, color: type.accent),
                title: const Text('Kamera ile çek'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(
                    source: ImageSource.camera,
                    onPicked: (p) {
                      if (slot == 'cup') {
                        _cupPath = p;
                      } else if (slot == 'saucer') {
                        _saucerPath = p;
                      } else {
                        _palmPath = p;
                      }
                    },
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: type.accent),
                title: const Text('Galeriden seç'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(
                    source: ImageSource.gallery,
                    onPicked: (p) {
                      if (slot == 'cup') {
                        _cupPath = p;
                      } else if (slot == 'saucer') {
                        _saucerPath = p;
                      } else {
                        _palmPath = p;
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FortuneGlassCard(
      accent: type.accent,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      type.accent.withValues(alpha: 0.5),
                      type.accent.withValues(alpha: 0.08),
                    ],
                  ),
                  boxShadow: AppThemeColors.glowShadow(type.accent, blur: 12),
                ),
                child: Icon(
                  _isCoffee ? Icons.coffee_rounded : Icons.back_hand_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCoffee ? 'Fincan & tabak fotoğrafları' : 'El fotoğrafı',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isCoffee
                          ? 'Fincan içini çekin; tabak isteğe bağlı'
                          : 'Avuç içini net ve aydınlık çekin',
                      style: TextStyle(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_isCoffee) ...[
            Row(
              children: [
                Expanded(
                  child: _PhotoSlot(
                    label: 'Fincan içi',
                    requiredSlot: true,
                    path: _cupPath,
                    accent: type.accent,
                    icon: Icons.coffee_rounded,
                    onTap: () => _showSourceSheet('cup'),
                    onClear: () {
                      setState(() => _cupPath = null);
                      _emit();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoSlot(
                    label: 'Tabak',
                    requiredSlot: false,
                    path: _saucerPath,
                    accent: type.accent,
                    icon: Icons.circle_outlined,
                    onTap: () => _showSourceSheet('saucer'),
                    onClear: () {
                      setState(() => _saucerPath = null);
                      _emit();
                    },
                  ),
                ),
              ],
            ),
          ] else if (_isPalm) ...[
            _PhotoSlot(
              label: 'Avuç içi',
              requiredSlot: true,
              path: _palmPath,
              accent: type.accent,
              icon: Icons.back_hand_rounded,
              tall: true,
              onTap: () => _showSourceSheet('palm'),
              onClear: () {
                setState(() => _palmPath = null);
                _emit();
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HandChip(
                    label: 'Sağ el',
                    emoji: '🤚',
                    selected: _hand == 'right',
                    accent: type.accent,
                    onTap: () {
                      setState(() => _hand = 'right');
                      _emit();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HandChip(
                    label: 'Sol el',
                    emoji: '🤛',
                    selected: _hand == 'left',
                    accent: type.accent,
                    onTap: () {
                      setState(() => _hand = 'left');
                      _emit();
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _TipBanner(
            text: _isCoffee
                ? 'En iyi sonuç için fincanı iyi aydınlatılmış ortamda ve net çekin.'
                : 'Elinizi kameraya düz tutun; çizgiler net görünsün.',
            accent: type.accent,
          ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.label,
    required this.requiredSlot,
    required this.path,
    required this.accent,
    required this.icon,
    required this.onTap,
    required this.onClear,
    this.tall = false,
  });

  final String label;
  final bool requiredSlot;
  final String? path;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null && path!.isNotEmpty;
    final height = tall ? 220.0 : 168.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            if (requiredSlot) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ] else
              Text(
                ' (opsiyonel)',
                style: TextStyle(
                  color: context.colors.onSurfaceMuted,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasImage
                      ? accent.withValues(alpha: 0.75)
                      : accent.withValues(alpha: 0.35),
                  width: hasImage ? 2 : 1.4,
                ),
                boxShadow: hasImage
                    ? AppThemeColors.glowShadow(accent, blur: 14)
                    : null,
                image: hasImage
                    ? DecorationImage(
                        image: FileImage(File(path!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: hasImage
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.14),
                          const Color(0xFF0F0A1E),
                        ],
                      ),
              ),
              child: Stack(
                children: [
                  if (!hasImage)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.16),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Icon(icon, color: accent, size: 26),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Dokunun',
                            style: TextStyle(
                              color: context.colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasImage)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Row(
                      children: [
                        _MiniAction(
                          icon: Icons.photo_camera_rounded,
                          label: 'Kamera',
                          onTap: onTap,
                        ),
                        const SizedBox(width: 8),
                        _MiniAction(
                          icon: Icons.photo_library_rounded,
                          label: 'Galeri',
                          onTap: onTap,
                        ),
                      ],
                    ),
                  ),
                  if (hasImage)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onClear,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HandChip extends StatelessWidget {
  const _HandChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? LinearGradient(
                    colors: [accent, Color.lerp(accent, Colors.deepPurple, 0.4)!],
                  )
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.8)
                  : accent.withValues(alpha: 0.28),
            ),
            boxShadow: selected
                ? AppThemeColors.glowShadow(accent, blur: 10)
                : null,
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: selected ? Colors.white : context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: accent.withValues(alpha: 0.1),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal — görsel fal türlerinde koordinatörden çağrılır.
Future<FortuneLocalImageInput?> showFortuneImageCaptureSheet({
  required BuildContext context,
  required FortuneTypeEntity type,
}) {
  return showModalBottomSheet<FortuneLocalImageInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      var input = const FortuneLocalImageInput();
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final valid = input.isValidFor(type);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF120A24),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: type.accent.withValues(alpha: 0.35)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                      const SizedBox(height: 12),
                      FortuneImageCapturePanel(
                        type: type,
                        initial: input,
                        onChanged: (v) => setSheetState(() => input = v),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: valid
                              ? () => Navigator.pop(ctx, input)
                              : null,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Falını Aç'),
                          style: FilledButton.styleFrom(
                            backgroundColor: type.accent,
                            disabledBackgroundColor:
                                type.accent.withValues(alpha: 0.35),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
