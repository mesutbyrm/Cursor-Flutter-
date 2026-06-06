import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/widgets/discover/discover_icon_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../../domain/repositories/fortune_repository.dart';
import '../providers/fortune_api_providers.dart';
import '../services/fortune_reading_service.dart';
import '../widgets/fortune_glass_card.dart';
import '../widgets/fortune_mystic_background.dart';

/// Tek fal türü oturumu — yerel yorum + oturumlu kullanıcıda API kaydı.
class FortuneSessionPage extends ConsumerStatefulWidget {
  const FortuneSessionPage({super.key, required this.type});

  final FortuneTypeEntity type;

  @override
  ConsumerState<FortuneSessionPage> createState() => _FortuneSessionPageState();
}

class _FortuneSessionPageState extends ConsumerState<FortuneSessionPage>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  final _service = FortuneReadingService();
  var _loading = false;
  bool? _yesNo;
  DateTime? _birthDate;
  late AnimationController _pulse;

  FortuneTypeEntity get type => widget.type;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (type.kind == FortuneSessionKind.yesNo && _yesNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evet veya Hayır seçin')),
      );
      return;
    }
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    var result = _service.generate(
      type,
      userInput: _input.text,
      yesNoChoice: _yesNo,
    );
    final authed = ref.read(authControllerProvider).valueOrNull;
    if (authed != null) {
      try {
        final saved = await ref.read(fortuneRepositoryProvider).save(
              SaveFortuneInput(
                type: type.title,
                slug: type.slug,
                question: _input.text.trim().isEmpty ? null : _input.text.trim(),
                summary: result.summary,
                detail: result.detail,
                answer: result.summary,
                luckyNumber: result.luckyNumber,
                luckyColor: result.luckyColor,
              ),
            );
        result = FortuneReadingResult(
          type: result.type,
          summary: result.summary,
          detail: result.detail,
          luckyNumber: result.luckyNumber,
          luckyColor: result.luckyColor,
          recordId: saved.id,
        );
        ref.invalidate(fortuneHistoryProvider);
      } catch (_) {
        // API yoksa yerel sonuç yine gösterilir.
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
    context.push(
      '/fortune/${type.slug}/result',
      extra: result,
    );
  }

  void _openWeb() {
    if (!Env.useNextAuth) return;
    context.push(
      CanlifalWebRoute.location(
        relativePath: '/fal/${type.slug}',
        title: type.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FortuneMysticBackground(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, top + 4, 12, 8),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      type.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (Env.useNextAuth)
                    IconButton(
                      icon: Icon(Icons.language_rounded),
                      color: context.colors.onSurfaceMuted,
                      onPressed: _openWeb,
                      tooltip: 'Web\'de aç',
                    )
                  else
                    SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _VisualForType(
                      type: type,
                      pulse: _pulse,
                      yesNo: _yesNo,
                      onYesNo: (v) => setState(() => _yesNo = v),
                      input: _input,
                      birthDate: _birthDate,
                      onPickDate: () async {
                        final now = DateTime.now();
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _birthDate ?? DateTime(1995, 6, 15),
                          firstDate: DateTime(1920),
                          lastDate: now,
                        );
                        if (d != null) setState(() => _birthDate = d);
                      },
                    ),
                    SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: type.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                type.ctaLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualForType extends StatelessWidget {
  const _VisualForType({
    required this.type,
    required this.pulse,
    required this.input,
    this.yesNo,
    this.onYesNo,
    this.birthDate,
    this.onPickDate,
  });

  final FortuneTypeEntity type;
  final AnimationController pulse;
  final TextEditingController input;
  final bool? yesNo;
  final ValueChanged<bool>? onYesNo;
  final DateTime? birthDate;
  final VoidCallback? onPickDate;

  @override
  Widget build(BuildContext context) {
    return FortuneGlassCard(
      accent: type.accent,
      padding: const EdgeInsets.all(20),
      child: switch (type.kind) {
        FortuneSessionKind.tarotCards => _TarotVisual(type: type, pulse: pulse),
        FortuneSessionKind.loveHeart => _LoveVisual(type: type, pulse: pulse),
        FortuneSessionKind.coffeeCup => _CoffeeVisual(type: type),
        FortuneSessionKind.zodiacWheel => _ZodiacVisual(type: type, pulse: pulse),
        FortuneSessionKind.palmScan => _PalmVisual(type: type),
        FortuneSessionKind.dreamText => _DreamInput(input: input),
        FortuneSessionKind.numberInput => _DateInput(
            birthDate: birthDate,
            onPick: onPickDate,
          ),
        FortuneSessionKind.yesNo => _YesNoVisual(
            yesNo: yesNo,
            onPick: onYesNo,
          ),
        FortuneSessionKind.pendulum => _PendulumVisual(pulse: pulse),
        FortuneSessionKind.runeStone => _RuneVisual(type: type),
        _ => _GenericVisual(type: type, pulse: pulse),
      },
    );
  }
}

class _TarotVisual extends StatelessWidget {
  const _TarotVisual({required this.type, required this.pulse});

  final FortuneTypeEntity type;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(type.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.onSurfaceVariant)),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ScaleTransition(
                scale: Tween(begin: 0.95, end: 1.05).animate(
                  CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 72,
                  height: 108,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        type.accent.withValues(alpha: 0.8),
                        Colors.black87,
                      ],
                    ),
                    border: Border.all(color: type.accent, width: 1.5),
                    boxShadow: AppThemeColors.glowShadow(type.accent),
                  ),
                  alignment: Alignment.center,
                  child: Text('🃏', style: TextStyle(fontSize: 32)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoveVisual extends StatelessWidget {
  const _LoveVisual({required this.type, required this.pulse});

  final FortuneTypeEntity type;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.1).animate(pulse),
          child: Text(type.emoji, style: TextStyle(fontSize: 80)),
        ),
        SizedBox(height: 12),
        Text(type.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}

class _CoffeeVisual extends StatelessWidget {
  const _CoffeeVisual({required this.type});

  final FortuneTypeEntity type;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3D2817),
            border: Border.all(color: type.accent, width: 2),
            boxShadow: AppThemeColors.glowShadow(type.accent),
          ),
          alignment: Alignment.center,
          child: Text('☕', style: TextStyle(fontSize: 56)),
        ),
        SizedBox(height: 16),
        Text(type.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}

class _ZodiacVisual extends StatelessWidget {
  const _ZodiacVisual({required this.type, required this.pulse});

  final FortuneTypeEntity type;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RotationTransition(
          turns: Tween(begin: 0.0, end: 0.02).animate(pulse),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: type.accent.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: AppThemeColors.glowShadow(type.accent),
            ),
            child: Center(
              child: Text('✨', style: TextStyle(fontSize: 56)),
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(type.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}

class _PalmVisual extends StatelessWidget {
  const _PalmVisual({required this.type});

  final FortuneTypeEntity type;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.pan_tool_alt_rounded,
            size: 100, color: type.accent.withValues(alpha: 0.9)),
        SizedBox(height: 12),
        Text(
          'Avucunu ekrana hizala',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(type.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}

class _DreamInput extends StatelessWidget {
  const _DreamInput({required this.input});

  final TextEditingController input;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Rüyanı kısaca anlat',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 10),
        TextField(
          controller: input,
          maxLines: 5,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Gece gördüğün rüyayı yaz…',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({this.birthDate, this.onPick});

  final DateTime? birthDate;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final label = birthDate != null
        ? '${birthDate!.day}.${birthDate!.month}.${birthDate!.year}'
        : 'Doğum tarihini seç';
    return Column(
      children: [
        Text(
          'Numeroloji için doğum tarihin',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: Icon(Icons.calendar_month_rounded),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppThemeColors.accentCyan,
            side: BorderSide(color: AppThemeColors.accentCyan.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
      ],
    );
  }
}

class _YesNoVisual extends StatelessWidget {
  const _YesNoVisual({this.yesNo, this.onPick});

  final bool? yesNo;
  final ValueChanged<bool>? onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Sorunu içinden geçir, sonra seç',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _YesNoButton(
                label: 'Evet',
                selected: yesNo == true,
                color: AppThemeColors.onlineGreen,
                onTap: () => onPick?.call(true),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _YesNoButton(
                label: 'Hayır',
                selected: yesNo == false,
                color: AppThemeColors.liveRed,
                onTap: () => onPick?.call(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _YesNoButton extends StatelessWidget {
  const _YesNoButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.35) : Colors.white10,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.white24,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? AppThemeColors.glowShadow(color, blur: 14) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: selected ? Colors.white : context.colors.onSurfaceMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _PendulumVisual extends StatelessWidget {
  const _PendulumVisual({required this.pulse});

  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: -0.08, end: 0.08).animate(pulse),
      child: Column(
        children: [
          const Text('🔮', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          Text('|', style: TextStyle(color: context.colors.onSurfaceMuted, fontSize: 24)),
          const Text('◆', style: TextStyle(color: AppThemeColors.accentCyan)),
        ],
      ),
    );
  }
}

class _RuneVisual extends StatelessWidget {
  const _RuneVisual({required this.type});

  final FortuneTypeEntity type;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: type.accent),
            boxShadow: AppThemeColors.glowShadow(type.accent),
          ),
          child: Text(type.emoji, style: TextStyle(fontSize: 40)),
        ),
        SizedBox(height: 12),
        Text(type.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}

class _GenericVisual extends StatelessWidget {
  const _GenericVisual({required this.type, required this.pulse});

  final FortuneTypeEntity type;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.95, end: 1.05).animate(pulse),
      child: Column(
        children: [
          Text(type.emoji, style: TextStyle(fontSize: 72)),
          SizedBox(height: 12),
          Text(type.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
