import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/cloud_upload_service.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../../membership/presentation/controllers/membership_controller.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../shorts/presentation/providers/shorts_providers.dart';
import '../../domain/entities/profile_extended_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../providers/payment_requests_notifier.dart';
import '../providers/profile_providers.dart';

final cloudMediaUploadProvider = Provider<CloudMediaUploadService>((ref) {
  return CloudMediaUploadService(ref.watch(dioProvider));
});

/// Cüzdan tabanlı üyelik özeti — profil hub bileşenleri için.
final profileMembershipInfoProvider =
    Provider.autoDispose<ProfileMembershipInfo>((ref) {
  final wallet = ref.watch(walletBalancesProvider).valueOrNull;
  return profileMembershipFromWallet(wallet);
});

/// Genişletilmiş profil — şehir, burç, doğum tarihi, seri.
final profileExtendedProvider =
    FutureProvider<ProfileExtendedEntity>((ref) async {
  ref.keepAlive();
  return ref.watch(profileRepositoryProvider).extendedProfile();
});

/// Detaylı kullanıcı istatistikleri.
final profileUserStatisticsProvider =
    FutureProvider<ProfileUserStatisticsEntity>((ref) async {
  ref.keepAlive();
  return ref.watch(profileRepositoryProvider).userStatistics();
});

/// Profil ziyaretçi sayısı (menü rozeti).
final profileVisitorBadgeProvider = Provider<int>((ref) {
  final stats = ref.watch(profileStatsProvider).valueOrNull;
  return stats?.profileViews ?? 0;
});

/// Profil hub yenileme — tüm ilgili provider'ları invalidate eder.
Future<void> refreshProfileHub(WidgetRef ref, {String? userId}) async {
  ref.invalidate(profileExtendedProvider);
  ref.invalidate(profileUserStatisticsProvider);
  ref.invalidate(profileStatsProvider);
  if (userId != null && userId.isNotEmpty) {
    ref.invalidate(shortVideoProfileStatsProvider(userId));
  }
  ref.invalidate(userLevelProvider);
  ref.invalidate(giftsReceivedSummaryProvider);
  ref.invalidate(userAchievementsProvider);
  ref.invalidate(walletBalancesProvider);
  ref.invalidate(membershipBadgesCatalogProvider);
  ref.invalidate(membershipCatalogProvider);
  ref.invalidate(membershipControllerProvider);
  ref.invalidate(paymentRequestsNotifierProvider);
  ref.invalidate(paymentMethodsProvider);
  unawaited(ref.read(authControllerProvider.notifier).refreshMe());
  unawaited(ref.read(walletBalancesProvider.notifier).refresh(force: true));
  unawaited(ref.read(profileExtendedProvider.future));
  unawaited(ref.read(profileUserStatisticsProvider.future));
  unawaited(ref.read(profileStatsProvider.future));
  unawaited(ref.read(userLevelProvider.future));
  unawaited(ref.read(giftsReceivedSummaryProvider.future));
  unawaited(ref.read(userAchievementsProvider.future));
}

/// Satın alma / ödeme onayı sonrası üyelik + cüzdan senkronu.
Future<void> refreshMembershipAfterPurchase(WidgetRef ref) async {
  ref.invalidate(membershipBadgesCatalogProvider);
  ref.invalidate(membershipCatalogProvider);
  ref.invalidate(membershipControllerProvider);
  ref.invalidate(walletBalancesProvider);
  ref.invalidate(paymentRequestsNotifierProvider);
  ref.invalidate(paymentMethodsProvider);
  await Future.wait([
    _ignore(ref.read(walletBalancesProvider.notifier).refresh(force: true)),
    _ignore(ref.read(membershipCatalogProvider.future)),
  ]);
}

Future<void> _ignore(Future<dynamic> future) async {
  try {
    await future;
  } catch (_) {}
}

/// Profil sayfasında gerçek zamanlı senkron — bildirim + periyodik yenileme.
class ProfileRealtimeSync extends ConsumerStatefulWidget {
  const ProfileRealtimeSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProfileRealtimeSync> createState() =>
      _ProfileRealtimeSyncState();
}

class _ProfileRealtimeSyncState extends ConsumerState<ProfileRealtimeSync> {
  Timer? _pollTimer;
  int _lastNotifCount = -1;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 120), (_) {
      if (!mounted) return;
      _softRefresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _softRefresh() {
    ref.read(walletBalancesProvider.notifier).refresh(force: false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationsUnreadCountProvider, (prev, next) {
      if (_lastNotifCount >= 0 && next != _lastNotifCount) {
        _softRefresh();
      }
      _lastNotifCount = next;
    });

    return widget.child;
  }
}

/// Avatar yükleme — presigned R2, yedek base64 PATCH /api/me.
class ProfileAvatarService {
  ProfileAvatarService(this._upload, this._repo);

  final CloudMediaUploadService _upload;
  final ProfileRepository _repo;

  Future<String> uploadAvatarFile(File file) async {
    try {
      return await _upload.uploadImageFile(
        file,
        folder: 'avatars',
        isPublic: true,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> saveAvatarUrl(String url) async {
    await _repo.updateMe(avatarUrl: url);
  }

  Future<void> deleteAvatar() async {
    await _repo.deleteAvatar();
  }
}

final profileAvatarServiceProvider = Provider<ProfileAvatarService>((ref) {
  return ProfileAvatarService(
    ref.watch(cloudMediaUploadProvider),
    ref.watch(profileRepositoryProvider),
  );
});
