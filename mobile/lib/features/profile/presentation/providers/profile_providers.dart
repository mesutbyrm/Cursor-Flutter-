import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../../domain/entities/referral_info_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/datasources/canlifal_user_api_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';

final profileRemoteProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(dioProvider));
});

final canlifalUserApiProvider = Provider<CanlifalUserApiDataSource>((ref) {
  return CanlifalUserApiDataSource(ref.watch(dioProvider));
});

final walletRemoteProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSource(ref.watch(dioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(profileRemoteProvider),
    ref.watch(canlifalUserApiProvider),
  );
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletRemoteProvider));
});

final userProfileProvider =
    FutureProvider.family<UserEntity, String>((ref, userId) async {
  return ref.watch(profileRepositoryProvider).getUser(userId);
});

final walletBalancesProvider = FutureProvider<WalletBalances>((ref) async {
  ref.keepAlive();
  return ref.watch(walletRepositoryProvider).balances();
});

final coinBalanceProvider = FutureProvider<int>((ref) async {
  final b = await ref.watch(walletBalancesProvider.future);
  return b.jeton;
});

final paymentConfigProvider = FutureProvider<PaymentConfigEntity>((ref) async {
  return ref.watch(walletRepositoryProvider).paymentConfig();
});

final jetonPackagesProvider =
    FutureProvider<List<JetonPackageEntity>>((ref) async {
  ref.keepAlive();
  return ref.watch(walletRepositoryProvider).jetonPackages();
});

final referralInfoProvider = FutureProvider<ReferralInfoEntity>((ref) async {
  return ref.watch(walletRepositoryProvider).referralInfo();
});

final profileStatsProvider = FutureProvider<ProfileStatsEntity>((ref) async {
  return ref.watch(profileRepositoryProvider).myStats();
});

final giftsReceivedSummaryProvider =
    FutureProvider<List<GiftReceivedSummaryEntity>>((ref) async {
  return ref.watch(profileRepositoryProvider).giftsReceivedSummary();
});

final broadcastHistoryProvider =
    FutureProvider<List<BroadcastHistoryItemEntity>>((ref) async {
  return ref.watch(profileRepositoryProvider).broadcastHistory();
});

final profileActivityProvider =
    FutureProvider<List<ProfileActivityItemEntity>>((ref) async {
  return ref.watch(profileRepositoryProvider).myActivity();
});

final allPaymentRequestsProvider =
    FutureProvider.autoDispose<List<CfcPaymentRequestEntity>>((ref) async {
  return ref.watch(walletRepositoryProvider).myPaymentRequests();
});

/// Yayın ekipmanı tercihleri (oturum boyunca).
final equipmentSettingsProvider =
    NotifierProvider<EquipmentSettingsNotifier, EquipmentSettings>(
  EquipmentSettingsNotifier.new,
);

class EquipmentSettings {
  const EquipmentSettings({
    this.micEnabled = true,
    this.cameraEnabled = true,
    this.beautyFilter = false,
    this.noiseCancel = true,
    this.hdStream = true,
  });

  final bool micEnabled;
  final bool cameraEnabled;
  final bool beautyFilter;
  final bool noiseCancel;
  final bool hdStream;

  EquipmentSettings copyWith({
    bool? micEnabled,
    bool? cameraEnabled,
    bool? beautyFilter,
    bool? noiseCancel,
    bool? hdStream,
  }) {
    return EquipmentSettings(
      micEnabled: micEnabled ?? this.micEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      beautyFilter: beautyFilter ?? this.beautyFilter,
      noiseCancel: noiseCancel ?? this.noiseCancel,
      hdStream: hdStream ?? this.hdStream,
    );
  }
}

class EquipmentSettingsNotifier extends Notifier<EquipmentSettings> {
  @override
  EquipmentSettings build() => const EquipmentSettings();

  void toggle(String key, bool value) {
    switch (key) {
      case 'mic':
        state = state.copyWith(micEnabled: value);
      case 'camera':
        state = state.copyWith(cameraEnabled: value);
      case 'beauty':
        state = state.copyWith(beautyFilter: value);
      case 'noise':
        state = state.copyWith(noiseCancel: value);
      case 'hd':
        state = state.copyWith(hdStream: value);
    }
  }
}
