import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_fortune_types.dart';

/// Randevu onayı sonucu — süre, jeton ve fal türü.
class PsychicBookingResult {
  const PsychicBookingResult({
    required this.minutes,
    required this.jeton,
    required this.fortuneType,
  });

  final int minutes;
  final int jeton;
  final String fortuneType;
}

final _bookingMinutesProvider = StateProvider.autoDispose<int>((ref) => 10);
final _bookingFortuneTypeProvider =
    StateProvider.autoDispose<String>((ref) => 'general');

/// Danışan — süre (5–30 dk), jeton ve fal türü seçimi.
Future<PsychicBookingResult?> showPsychicBookingSheet(
  BuildContext context, {
  required PsychicEntity psychic,
  int initialMinutes = 10,
  String? initialFortuneType,
  bool isStaff = false,
}) {
  return showModalBottomSheet<PsychicBookingResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProviderScope(
      overrides: [
        _bookingMinutesProvider.overrideWith((ref) => initialMinutes),
        _bookingFortuneTypeProvider.overrideWith(
          (ref) => initialFortuneType ?? psychicFortuneTypesForPsychic(psychic.specialties).first.key,
        ),
      ],
      child: _PsychicBookingSheet(psychic: psychic, isStaff: isStaff),
    ),
  );
}

class _PsychicBookingSheet extends ConsumerWidget {
  const _PsychicBookingSheet({
    required this.psychic,
    this.isStaff = false,
  });

  final PsychicEntity psychic;
  final bool isStaff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = PsychicDurationOption.forPsychic(psychic.pricePerMinute);
    final selectedMinutes = ref.watch(_bookingMinutesProvider);
    final selectedType = ref.watch(_bookingFortuneTypeProvider);
    final fortuneTypes = psychicFortuneTypesForPsychic(psychic.specialties);
    final selected = options.firstWhere(
      (o) => o.minutes == selectedMinutes,
      orElse: () => options[1],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E2A48).withValues(alpha: 0.96),
                  const Color(0xFF120A24).withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.video_chat_rounded,
                    color: AppThemeColors.accentCyan,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Randevu Al',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      text: psychic.name,
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: ' ile canlı fal seansı',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isStaff) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF64B5F6)),
                      ),
                      child: const Text(
                        'Staff hesabı — seans için jeton düşülmez',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF80D8FF),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Süre Seçin',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((opt) {
                      final active = opt.minutes == selectedMinutes;
                      return ChoiceChip(
                        label: Text(opt.label),
                        selected: active,
                        onSelected: (_) => ref
                            .read(_bookingMinutesProvider.notifier)
                            .state = opt.minutes,
                        selectedColor: AppThemeColors.accentPurple,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : Colors.white70,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        side: BorderSide(
                          color: active
                              ? AppThemeColors.accentPink
                              : Colors.white24,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fal Türü Seçin',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fortuneTypes.map((type) {
                      final active = type.key == selectedType;
                      return FilterChip(
                        label: Text(type.label),
                        selected: active,
                        onSelected: (_) => ref
                            .read(_bookingFortuneTypeProvider.notifier)
                            .state = type.key,
                        selectedColor: AppThemeColors.accentPurple.withValues(alpha: 0.85),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : Colors.white70,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        side: BorderSide(
                          color: active
                              ? AppThemeColors.accentPink
                              : Colors.white24,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${selected.minutes} dk',
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Süre',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: Colors.white12),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                isStaff ? 'Ücretsiz' : '${selected.totalJeton} jeton',
                                style: const TextStyle(
                                  color: AppThemeColors.accentCyan,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ücret',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'İsteğiniz falcıya iletilecek. Kabul ettiğinde seans başlar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ActionBtn(
                    label: 'Falcıya Bağlan',
                    icon: Icons.send_rounded,
                    gradient: const [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                    onTap: () => Navigator.pop(
                      context,
                      PsychicBookingResult(
                        minutes: selected.minutes,
                        jeton: selected.totalJeton,
                        fortuneType: selectedType,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
