import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_date_pickers.dart';
import '../../domain/fortune_zodiac.dart';
import '../../data/fortune_birth_profile_store.dart';
import '../providers/fortune_birth_profile_provider.dart';
import '../widgets/ultra_premium/ultra_fortune_liquid_surface.dart';
import '../widgets/ultra_premium/ultra_fortune_tokens.dart';

/// Fal & Tarot hub — burç kartı ve «Falına bak» CTA.
class FortuneZodiacHubCard extends ConsumerWidget {
  const FortuneZodiacHubCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(fortuneBirthProfileProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: profileAsync.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => _PromptCard(
          onTap: () => showFortuneBirthProfileSheet(context, ref),
        ),
        data: (profile) {
          if (profile == null) {
            return _PromptCard(
              onTap: () => showFortuneBirthProfileSheet(context, ref),
            );
          }
          final zodiac = FortuneZodiac.fromBirthDate(profile.birthDate);
          return _ZodiacCard(
            zodiac: zodiac,
            birthSummary: formatFortuneBirthSummary(profile),
            onReadFortune: () => context.push('/fortune/yildiz-haritasi'),
            onEditBirth: () => showFortuneBirthProfileSheet(
              context,
              ref,
              initial: profile,
            ),
          );
        },
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: UltraFortuneLiquidSurface(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      UltraFortuneTokens.metallicGold.withValues(alpha: 0.5),
                      UltraFortuneTokens.spaceViolet.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: const Text('✨', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Burcunu keşfet',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Doğum tarihi ve saatini gir; sana özel falını öğren.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZodiacCard extends StatelessWidget {
  const _ZodiacCard({
    required this.zodiac,
    required this.birthSummary,
    required this.onReadFortune,
    required this.onEditBirth,
  });

  final FortuneZodiac zodiac;
  final String birthSummary;
  final VoidCallback onReadFortune;
  final VoidCallback onEditBirth;

  @override
  Widget build(BuildContext context) {
    return UltraFortuneLiquidSurface(
      goldAccent: true,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(zodiac.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${zodiac.sign} Burcu',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      zodiac.dateRange,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      birthSummary,
                      style: TextStyle(
                        color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditBirth,
                icon: Icon(
                  Icons.edit_calendar_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                tooltip: 'Doğum bilgisini düzenle',
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onReadFortune,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Falına bak'),
            style: FilledButton.styleFrom(
              backgroundColor: UltraFortuneTokens.metallicGold,
              foregroundColor: const Color(0xFF1A0A32),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Doğum tarihi/saati toplama — hub girişinde otomatik açılabilir.
Future<void> showFortuneBirthProfileSheet(
  BuildContext context,
  WidgetRef ref, {
  FortuneBirthProfile? initial,
}) async {
  var birthDate = initial?.birthDate;
  var birthTime = initial?.birthTime ?? const TimeOfDay(hour: 12, minute: 0);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheet) {
          final valid = birthDate != null;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF120A24),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.35),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Doğum tarihi ve saati',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Burcunu ve sana özel fal yorumunu göstermek için '
                        'doğum bilgilerine ihtiyacımız var. Profiline kaydedilir; '
                        'istediğin zaman değiştirebilirsin.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showAuthBirthDatePicker(
                            context,
                            initial: birthDate,
                          );
                          if (picked != null) {
                            setSheet(() => birthDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: Text(
                          birthDate == null
                              ? 'Doğum tarihi seç'
                              : formatBirthDate(birthDate!),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.5),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showAuthBirthTimePicker(
                            context,
                            initial: birthTime,
                          );
                          if (picked != null) {
                            setSheet(() => birthTime = picked);
                          }
                        },
                        icon: const Icon(Icons.schedule_rounded),
                        label: Text(birthTime.format(context)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.5),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: valid
                            ? () async {
                                await saveFortuneBirthProfile(
                                  ref,
                                  birthDate: birthDate!,
                                  birthTime: birthTime,
                                );
                                if (context.mounted) Navigator.pop(context);
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: UltraFortuneTokens.metallicGold,
                          foregroundColor: const Color(0xFF1A0A32),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Kaydet'),
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

/// Hub açılışında doğum bilgisi yoksa bir kez sheet göster.
final _fortuneBirthPromptShown = <String>{};

void maybePromptFortuneBirthOnHub(
  BuildContext context,
  WidgetRef ref,
) {
  final me = ref.read(authControllerProvider).valueOrNull;
  if (me == null) return;
  if (_fortuneBirthPromptShown.contains(me.id)) return;

  ref.read(fortuneBirthProfileProvider.future).then((profile) async {
    if (!context.mounted || profile != null) return;
    final store = await ref.read(fortuneBirthProfileStoreProvider.future);
    if (store.read(me.id) != null) return;
    if (!context.mounted) return;
    _fortuneBirthPromptShown.add(me.id);
    await showFortuneBirthProfileSheet(context, ref);
  });
}
