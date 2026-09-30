import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/navigation/wallet_navigation.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/psychic_entity.dart';
import '../controllers/psychic_flow.dart';
import '../widgets/psychic_booking_sheet.dart';

/// Canlı falcı listesi / profil — hızlı sesli veya görüntülü seans isteği.
Future<void> openPsychicQuickSession(
  BuildContext context,
  WidgetRef ref, {
  required PsychicEntity psychic,
  required bool preferVideo,
}) async {
  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seans için giriş yapın')),
    );
    return;
  }
  if (!psychic.isOnline) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Falcı şu an çevrimdışı.')),
    );
    return;
  }
  if (psychic.hasLiveBroadcast) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Falcı canlı yayında — yayın bitince seans alabilirsiniz.'),
      ),
    );
    return;
  }

  final isStaff = ref.read(walletBalancesProvider).valueOrNull?.isStaff == true;
  final balance = ref.watch(coinBalanceProvider) ?? 0;

  final result = await showPsychicBookingSheet(
    context,
    psychic: psychic,
    isStaff: isStaff,
    initialFortuneType: preferVideo ? 'general' : 'general',
  );
  if (!context.mounted || result == null) return;

  if (!isStaff && balance < result.jeton) {
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    await showInsufficientJetonDialog(
      context,
      message:
          'Yetersiz $jetonLabel. Gerekli: ${result.jeton}, bakiye: $balance',
      ref: ref,
    );
    return;
  }

  await PsychicFlow.bookAndOpenWaiting(
    ref: ref,
    router: GoRouter.of(context),
    psychic: psychic,
    durationMinutes: result.minutes,
    totalJeton: result.jeton,
    fortuneType: result.fortuneType,
    staffExempt: isStaff,
  );
  if (!context.mounted) return;
  if (!preferVideo) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sesli seans — görüşme ekranında kamerayı kapatabilirsiniz.',
        ),
      ),
    );
  }
}
