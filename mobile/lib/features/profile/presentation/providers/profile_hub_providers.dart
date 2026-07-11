import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/cloud_upload_service.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../domain/entities/profile_extended_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../providers/profile_providers.dart';

final cloudMediaUploadProvider = Provider<CloudMediaUploadService>((ref) {
  return CloudMediaUploadService(ref.watch(dioProvider));
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
  ref.invalidate(userLevelProvider);
  ref.invalidate(giftsReceivedSummaryProvider);
  ref.invalidate(userAchievementsProvider);
  ref.invalidate(walletBalancesProvider);
  await Future.wait([
    ref.read(authControllerProvider.notifier).refreshMe(),
    ref.read(walletBalancesProvider.notifier).refresh(force: true),
    ref.read(profileExtendedProvider.future),
    ref.read(profileUserStatisticsProvider.future),
    ref.read(profileStatsProvider.future),
    ref.read(userLevelProvider.future),
    ref.read(giftsReceivedSummaryProvider.future),
    ref.read(userAchievementsProvider.future),
  ]);
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
