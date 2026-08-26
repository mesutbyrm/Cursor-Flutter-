import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/navigation/wallet_navigation.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium/live_badge.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_booking_feedback_provider.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_tip_sheet.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_flow.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_booking_sheet.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_favorite_button.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_fortune_types.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

final _profileBookingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Falcı profil detayı — randevu al ve bekleme ekranına yönlendir.
class PsychicProfileScreen extends ConsumerWidget {
  const PsychicProfileScreen({super.key, required this.psychicId});

  final String psychicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final psychicAsync = ref.watch(psychicDetailProvider(psychicId));
    final balance = ref.watch(coinBalanceProvider) ?? 0;
    final isStaff = ref.watch(walletBalancesProvider).valueOrNull?.isStaff == true;
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
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ApiException.userMessage(e)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(psychicDetailProvider(psychicId)),
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
                data: (psychic) {
                  if (psychic == null) {
                    return const Center(child: Text('Falcı bulunamadı.'));
                  }
                  return _ProfileBody(
                    psychic: psychic,
                    balance: balance,
                    isStaff: isStaff,
                    booking: booking,
                    onBook: () => _book(context, ref, psychic, balance, isStaff),
                    onTip: () => _tip(context, ref, psychic, balance, isStaff),
                  );
                },
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, top: 4),
                  child: PsychicFavoriteButton(tellerId: psychicId),
                ),
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
    bool isStaff,
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

    final result = await showPsychicBookingSheet(
      context,
      psychic: psychic,
      isStaff: isStaff,
    );
    if (!context.mounted || result == null) return;

    if (!isStaff && balance < result.jeton) {
      await showInsufficientJetonDialog(
        context,
        message: 'Yetersiz jeton. Gerekli: ${result.jeton}, bakiye: $balance',
        ref: ref,
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
        staffExempt: isStaff,
      );
    } finally {
      ref.read(_profileBookingProvider.notifier).state = false;
    }
  }

  Future<void> _tip(
    BuildContext context,
    WidgetRef ref,
    PsychicEntity psychic,
    int balance,
    bool isStaff,
  ) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bahşiş için giriş yapın')),
      );
      return;
    }
    if (isStaff) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff hesabından bahşiş gönderilemez')),
      );
      return;
    }

    final amount = await showPsychicTipSheet(
      context,
      psychicName: psychic.name,
      jetonBalance: balance,
    );
    if (!context.mounted || amount == null) return;

    if (balance < amount) {
      await showInsufficientJetonDialog(
        context,
        message: 'Yetersiz jeton. Gerekli: $amount, bakiye: $balance',
        ref: ref,
      );
      return;
    }

    final ok = await ref.read(livePsychicsRepositoryProvider).sendTip(
          amount: amount,
          tellerId: psychic.id,
          tellerUserId: psychic.userId,
        );
    if (!context.mounted) return;

    if (ok) {
      await ref.refreshWalletCache();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$amount jeton bahşiş gönderildi — teşekkürler!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bahşiş gönderilemedi')),
      );
    }
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({
    required this.psychic,
    required this.balance,
    required this.isStaff,
    required this.booking,
    required this.onBook,
    required this.onTip,
  });

  final PsychicEntity psychic;
  final int balance;
  final bool isStaff;
  final bool booking;
  final VoidCallback onBook;
  final VoidCallback onTip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(psychicReviewsProvider(psychic.id));
    final awardsAsync = ref.watch(psychicAwardsProvider(psychic.id));
    final giftsAsync = ref.watch(psychicGiftsProvider(psychic.id));
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
                            canlifalImageProvider(psychic.avatarUrl!),
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
            isStaff
                ? 'Staff hesabı — jeton düşülmez'
                : '${psychic.pricePerMinute} jeton/dk · Bakiye: $balance jeton',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isStaff
                  ? const Color(0xFF80D8FF)
                  : Colors.white.withValues(alpha: 0.6),
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
        if (!isStaff) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTip,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemeColors.accentPink,
                side: BorderSide(
                  color: AppThemeColors.accentPink.withValues(alpha: 0.65),
                ),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.card_giftcard_rounded),
              label: const Text(
                'Bahşiş Ver',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
        reviewsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 28),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => _SectionRetry(
            message: 'Yorumlar yüklenemedi',
            onRetry: () => ref.invalidate(psychicReviewsProvider(psychic.id)),
          ),
          data: (reviews) {
            if (reviews.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Text(
                  'Yorumlar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                ...reviews.take(5).map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    r.clientName ?? 'Danışan',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '★ ${r.rating}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD54F),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (r.comment != null &&
                                  r.comment!.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  r.comment!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
        awardsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => _SectionRetry(
            message: 'Ödüller yüklenemedi',
            onRetry: () => ref.invalidate(psychicAwardsProvider(psychic.id)),
          ),
          data: (awards) {
            if (awards.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Text(
                  'Ödüller',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                ...awards.take(5).map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Color(0xFFFFD54F),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.title.isNotEmpty ? a.title : a.awardType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
        giftsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => _SectionRetry(
            message: 'Hediyeler yüklenemedi',
            onRetry: () => ref.invalidate(psychicGiftsProvider(psychic.id)),
          ),
          data: (gifts) {
            if (gifts.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Text(
                  'Hediyeler',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                ...gifts.take(5).map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard_rounded,
                              color: AppThemeColors.accentPink,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                g.senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              '${g.giftCount}×',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            );
          },
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

class _SectionRetry extends StatelessWidget {
  const _SectionRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}
