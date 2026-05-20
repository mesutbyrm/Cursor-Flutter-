import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/referral_info_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';

final profileRemoteProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(dioProvider));
});

final walletRemoteProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSource(ref.watch(dioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletRemoteProvider));
});

final userProfileProvider =
    FutureProvider.family<UserEntity, String>((ref, userId) async {
  return ref.watch(profileRepositoryProvider).getUser(userId);
});

final coinBalanceProvider = FutureProvider<int>((ref) async {
  return ref.watch(walletRepositoryProvider).coinBalance();
});

final jetonPackagesProvider =
    FutureProvider<List<JetonPackageEntity>>((ref) async {
  return ref.watch(walletRepositoryProvider).jetonPackages();
});

final referralInfoProvider = FutureProvider<ReferralInfoEntity>((ref) async {
  return ref.watch(walletRepositoryProvider).referralInfo();
});
