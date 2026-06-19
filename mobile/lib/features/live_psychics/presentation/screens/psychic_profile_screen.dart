import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium/live_badge.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_booking_feedback_provider.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_flow.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_booking_sheet.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_fortune_types.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';

final _profileBookingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Falcı profil detayı — randevu al ve bekleme ekranına yönlendir.
class PsychicProfileScreen extends ConsumerWidget {
  const PsychicProfileScreen({super.key, required this.psychicId});

  final String psychicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final psychicAsync = ref.watch(psychicDetailProvider(psychicId));
    final balance = ref.watch(coinBalanceProvider).valueOrNull ?? 0;
    final booking = ref.watch(_profileBookingProvider);

    ref.listen(psychicBookingFeedbackProvider, (prev, next) {
      if (next != null && next.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            backgroundColor: const Color(0xFF5C1A1A),
          ),
        );
        ref.read(psychicBookingFeedbackProvider.notifier).state = null;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0618),
      body: CosmicGalaxyBackground(
        child: Stack(
          children: [
            SafeArea(
              child: psychicAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
                data: (psychic) {
                  if (psychic == null) {
                    return const Center(child: Text('Falcı bulunamadı.'));
                  }
                  return _ProfileBody(
                    psychic: psychic,
                    balance: balance,
                    booking: booking,
                    onBook: () => _book(context, ref, psychic, balance),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 8),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    tooltip: 'Geri',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _book(
    BuildContext context,
    WidgetRef ref,
    PsychicEntity psychic,
    int balance,
  ) async {
    if (ref.read(_profileBookingProvider)) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Randevu için giriş yapın')),
      );
      return;
    }
    if (!psychic.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falcı şu an çevrimdışı.')),
      );
      return;
    }

    final result = await showPsychicBookingSheet(context, psychic: psychic);
    if (!context.mounted || result == null) return;

    if (balance < result.jeton) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yetersiz jeton. Gerekli: ${result.jeton}, bakiye: $balance',
          ),
        ),
      );
      return;
    }

    ref.read(_profileBookingProvider.notifier).state = true;
    try {
      await PsychicFlow.bookAndOpenWaiting(
        ref: ref,
        router: GoRouter.of(context),
        psychic: psychic,
        durationMinutes: result.minutes,
        totalJeton: result.jeton,
        fortuneType: result.fortuneType,
      );
    } finally {
      ref.read(_profileBookingProvider.notifier).state = false;
    }
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.psychic,
    required this.balance,
    required this.booking,
    required this.onBook,
  });

  final PsychicEntity psychic;
  final int balance;
  final bool booking;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final fortuneTypes = psychicFortuneTypesForPsychic(psychic.specialties);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const SizedBox(height: 36),
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppThemeColors.accentPink,
                      AppThemeColors.accentPurple,
                    ],
                  ),
                ),
                child: psychic.avatarUrl != null && psychic.avatarUrl!.isNotEmpty
                    ? CircleAvatar(
                        radius: 52,
                        backgroundImage:
                            CachedNetworkImageProvider(psychic.avatarUrl!),
                      )
                    : const UserAvatar(radius: 52),
              ),
              if (psychic.isOnline)
                const Positioned(
                  right: 6,
                  bottom: 6,
                  child: LiveBadge(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              psychic.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.verified_rounded,
              color: AppThemeColors.diamondBlue,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            if (psychic.isOnline)
              _Pill(label: 'Çevrimiçi', color: const Color(0xFF00E676)),
            if (psychic.rating > 0)
              _Pill(
                label: '★ ${psychic.rating.toStringAsFixed(1)}',
                color: const Color(0xFFFFD54F),
                foreground: Colors.black87,
              ),
            _Pill(
              label: '${psychic.reviewCount} seans',
              color: Colors.white24,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          psychic.displayCategory,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
        if (psychic.bio != null && psychic.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            psychic.bio!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: fortuneTypes
              .map(
                (t) => Chip(
                  label: Text(t.label, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  side: const BorderSide(color: Colors.white24),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        if (psychic.pricePerMinute > 0)
          Text(
            '${psychic.pricePerMinute} jeton/dk · Bakiye: $balance jeton',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: psychic.isOnline && !booking ? onBook : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.accentPurple,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: booking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.calendar_month_rounded),
            label: Text(
              booking ? 'İstek gönderiliyor…' : 'Randevu Al',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    this.foreground = Colors.white,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color == Colors.white24 ? 1 : 0.2),
        borderRadius: BorderRadius.circular(20),
        border: color == Colors.white24
            ? null
            : Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
