import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../providers/home_providers.dart';
import '../live_fortune/live_fortune_close_dialog.dart';

/// Canlı fal randevu → bekleme → seans akışı (üretim API).
class LiveFortuneFlow {
  LiveFortuneFlow._();

  static Future<LiveFortuneSessionEntity?> bookAndOpenWaiting({
    required BuildContext context,
    required WidgetRef ref,
    required LiveFortuneTellerEntity teller,
    required int durationMinutes,
    required int totalJeton,
    String? fortuneType,
  }) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      _snack(context, 'Randevu için giriş yapın');
      return null;
    }
    final balance =
        ref.read(coinBalanceProvider).valueOrNull ?? user.coinBalance;
    if (balance < totalJeton) {
      _snack(context, 'Yetersiz jeton. Gerekli: $totalJeton');
      return null;
    }

    final remote = ref.read(homeRemoteProvider);
    final displayName = _displayName(user);
    final type = fortuneType ??
        (teller.specialties.isNotEmpty ? teller.specialties.first : 'general');

    final created = await remote.createFortuneTellerSession(
      teller.id,
      tellerUserId: teller.userId ?? teller.trtcUserId,
      clientName: displayName,
      durationMinutes: durationMinutes,
      totalJeton: totalJeton,
      fortuneType: type,
    );
    if (!context.mounted || created == null) {
      if (context.mounted) _snack(context, 'Randevu oluşturulamadı');
      return null;
    }

    final session = LiveFortuneSessionEntity(
      sessionId: created.sessionId,
      teller: teller,
      durationMinutes: durationMinutes,
      totalJeton: totalJeton,
      tellerUserId: created.tellerUserId ?? teller.trtcUserId,
      clientId: created.clientId ?? user.id,
      isClient: true,
    );

    if (!context.mounted) return session;
    context.push('/canli-falcilar/${teller.id}/waiting', extra: session);
    return session;
  }

  /// Bekleme iptal — jeton iadesi için `end` çağrılır.
  static Future<bool> cancelWaiting({
    required BuildContext context,
    required WidgetRef ref,
    required String sessionId,
    String? tellerName,
  }) async {
    final ok = await showLiveFortuneCloseDialog(
      context,
      title: 'Randevuyu iptal et?',
      message: tellerName != null && tellerName.isNotEmpty
          ? '$tellerName ile randevunuzu iptal etmek istediğinize emin misiniz?'
          : 'Randevunuzu iptal etmek istediğinize emin misiniz?',
      confirmLabel: 'İptal Et',
    );
    if (!ok || !context.mounted) return false;
    await ref.read(homeRemoteProvider).endFortuneSession(sessionId);
    ref.invalidate(coinBalanceProvider);
    if (!context.mounted) return true;
    context.go('/canli-falcilar');
    return true;
  }

  /// Aktif seansı sonlandır.
  static Future<bool> closeSession({
    required BuildContext context,
    required WidgetRef ref,
    required String sessionId,
    bool isClient = true,
  }) async {
    final ok = await showLiveFortuneCloseDialog(
      context,
      title: 'Seansı kapat?',
      message: isClient
          ? 'Canlı fal oturumundan çıkmak istediğinize emin misiniz?'
          : 'Seansı sonlandırmak istediğinize emin misiniz?',
      confirmLabel: 'Kapat',
    );
    if (!ok || !context.mounted) return false;
    await ref.read(homeRemoteProvider).endFortuneSession(sessionId);
    if (!context.mounted) return true;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/canli-falcilar');
    }
    return true;
  }

  static String _displayName(UserEntity user) {
    final dn = user.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    return user.username;
  }

  static void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
