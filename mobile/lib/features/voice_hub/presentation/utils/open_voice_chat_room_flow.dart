import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/network/api_exception.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/data/datasources/live_remote_datasource.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';

/// canlifal.com — sesli sohbet odası aç (normal 100 / VIP 5000 jeton).
Future<void> showOpenVoiceChatRoomFlow(BuildContext context, WidgetRef ref) async {
  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) {
    if (context.mounted) context.push('/login');
    return;
  }

  const normalCost = LiveRemoteDataSource.voiceRoomNormalOpenJetonCost;
  const vipCost = LiveRemoteDataSource.voiceRoomVipOpenJetonCost;
  var balance = ref.read(walletBalancesProvider).valueOrNull?.jeton ?? 0;
  // Önbellekli bakiye ile hemen sheet aç; güncelleme arka planda.
  ref.read(walletBalancesProvider.future).then((b) {
    balance = b.jeton;
  }).catchError((_) {});

  final choice = await showModalBottomSheet<_OpenRoomChoice>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: const Color(0xFF12081F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sesli Sohbet Odası Aç',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Sesli oda açma: $normalCost jeton\nVIP oda açma: $vipCost jeton / ay',
              style: TextStyle(
                color: ctx.colors.onSurfaceMuted.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bakiyeniz: $balance jeton',
              style: TextStyle(
                color: balance >= normalCost
                    ? AppThemeColors.accentCyan
                    : AppThemeColors.liveRed,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(ctx, rootNavigator: true).pop(_OpenRoomChoice.free),
              icon: const Icon(Icons.volunteer_activism_rounded),
              label: const Text('Ücretsiz oda aç · 0 jeton'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemeColors.accentCyan,
                side: BorderSide(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.7),
                ),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx, rootNavigator: true)
                  .pop(_OpenRoomChoice.standard),
              icon: const Icon(Icons.mic_rounded),
              label: Text('Sesli oda aç · $normalCost jeton'),
              style: FilledButton.styleFrom(
                backgroundColor: AppThemeColors.accentPurple,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(ctx, rootNavigator: true).pop(_OpenRoomChoice.vip),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: Text('VIP oda aç · $vipCost jeton/ay'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemeColors.coinGold,
                side: const BorderSide(color: AppThemeColors.coinGold),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
              child: const Text('İptal'),
            ),
          ],
        ),
      ),
    ),
  );

  if (choice == null || !context.mounted) return;

  _showLoadingDialog(context);

  final cost = switch (choice) {
    _OpenRoomChoice.vip => vipCost,
    _OpenRoomChoice.standard => normalCost,
    _OpenRoomChoice.free => 0,
  };
  ref.invalidate(walletBalancesProvider);
  try {
    balance = (await ref.read(walletBalancesProvider.future).timeout(
          const Duration(seconds: 12),
        ))
        .jeton;
  } catch (_) {
    balance = ref.read(walletBalancesProvider).valueOrNull?.jeton ?? balance;
  }

  if (!context.mounted) {
    _dismissLoadingDialog(context);
    return;
  }

  if (cost > 0 && balance < cost) {
    _dismissLoadingDialog(context);
    _showSnackBar(
      context,
      SnackBar(
        content: Text('Yetersiz jeton ($cost gerekli, $balance mevcut).'),
        action: SnackBarAction(
          label: 'Jeton yükle',
          onPressed: () => openJetonStore(context, ref: ref),
        ),
      ),
    );
    return;
  }

  await _createAndEnter(
    context,
    ref,
    choice: choice,
    loadingVisible: true,
  );
}

enum _OpenRoomChoice { free, standard, vip }

void _showLoadingDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: AppThemeColors.accentPink),
    ),
  );
}

void _dismissLoadingDialog(BuildContext context) {
  final nav = Navigator.of(context, rootNavigator: true);
  if (nav.canPop()) nav.pop();
}

void _showSnackBar(BuildContext context, SnackBar snackBar) {
  final rootCtx = rootNavigatorKey.currentContext ?? context;
  ScaffoldMessenger.maybeOf(rootCtx)?.showSnackBar(snackBar);
}

Future<void> _createAndEnter(
  BuildContext context,
  WidgetRef ref, {
  required _OpenRoomChoice choice,
  bool loadingVisible = false,
}) async {
  if (!loadingVisible) {
    _showLoadingDialog(context);
  }

  try {
    final user = ref.read(authControllerProvider).valueOrNull;
    final roomType = switch (choice) {
      _OpenRoomChoice.free => 'free',
      _OpenRoomChoice.vip => 'vip',
      _OpenRoomChoice.standard => 'normal',
    };
    var room = await ref
        .read(liveRepositoryProvider)
        .createVoiceChatRoom(
          vip: choice == _OpenRoomChoice.vip,
          roomType: roomType,
          roomName: user?.display ?? user?.username,
        )
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw Exception(
            'Oda açma zaman aşımı. İnternet bağlantınızı kontrol edin.',
          ),
        );
    if (room.apiRoomKey.isEmpty) {
      ref.invalidate(voiceRoomsProvider);
      final rooms = await ref
          .read(voiceRoomsProvider.future)
          .timeout(const Duration(seconds: 20), onTimeout: () => <VoiceRoomEntity>[]);
      final me = user?.id;
      if (me != null && me.isNotEmpty) {
        VoiceRoomEntity? newest;
        for (final r in rooms) {
          if (r.ownerId == me && r.apiRoomKey.isNotEmpty) {
            newest = r;
            break;
          }
        }
        if (newest != null) room = newest;
      }
    }
    if (room.apiRoomKey.isEmpty) {
      throw Exception(
        'Oda oluşturuldu ancak oda kimliği alınamadı. '
        'Birkaç saniye sonra Odalar listesinden tekrar deneyin.',
      );
    }
    ref.invalidate(voiceRoomsProvider);
    ref.invalidate(walletBalancesProvider);
    if (!context.mounted) return;
    _dismissLoadingDialog(context);
    _showSnackBar(
      context,
      SnackBar(
        content: Text(
          switch (choice) {
            _OpenRoomChoice.vip => 'VIP sesli oda açıldı',
            _OpenRoomChoice.free => 'Ücretsiz sesli oda açıldı',
            _OpenRoomChoice.standard => 'Sesli sohbet odanız açıldı',
          },
        ),
      ),
    );
    await openVoiceRoomWithVipGate(
      context,
      ref,
      room,
      skipVipGateForOwner: true,
    );
  } catch (e) {
    if (!context.mounted) return;
    _dismissLoadingDialog(context);
    final msg = ApiException.userMessage(e);
    final lower = msg.toLowerCase();
    if (lower.contains('zaten') ||
        lower.contains('already') ||
        lower.contains('mevcut') ||
        lower.contains('bir oda')) {
      final user = ref.read(authControllerProvider).valueOrNull;
      ref.invalidate(voiceRoomsProvider);
      try {
        final rooms = await ref.read(voiceRoomsProvider.future);
        final me = user?.id;
        VoiceRoomEntity? owned;
        if (me != null) {
          for (final r in rooms) {
            if (r.ownerId == me && r.apiRoomKey.isNotEmpty) {
              owned = r;
              break;
            }
          }
        }
        if (owned != null && context.mounted) {
          _showSnackBar(
            context,
            const SnackBar(content: Text('Mevcut odanıza yönlendiriliyorsunuz…')),
          );
          await openVoiceRoomWithVipGate(
            context,
            ref,
            owned,
            skipVipGateForOwner: true,
          );
          return;
        }
      } catch (_) {}
    }
    if (msg.toLowerCase().contains('yetersiz') ||
        msg.toLowerCase().contains('jeton')) {
      _showSnackBar(
        context,
        SnackBar(
          content: Text(msg),
          action: SnackBarAction(
            label: 'Jeton yükle',
            onPressed: () => openJetonStore(context, ref: ref),
          ),
        ),
      );
      return;
    }
    _showSnackBar(context, SnackBar(content: Text(msg)));
  }
}
