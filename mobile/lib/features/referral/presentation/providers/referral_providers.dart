import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/referral_remote_datasource.dart';
import '../../domain/entities/referral_entities.dart';

final referralRemoteDataSourceProvider = Provider<ReferralRemoteDataSource>((ref) {
  return ReferralRemoteDataSource(ref.watch(dioProvider));
});

final referralStatsProvider = FutureProvider<ReferralStatsEntity>((ref) async {
  return ref.watch(referralRemoteDataSourceProvider).fetchStats();
});

final referralUsersProvider = FutureProvider<List<ReferralUserEntity>>((ref) async {
  return ref.watch(referralRemoteDataSourceProvider).fetchUsers();
});

final referralEarningsProvider = FutureProvider<ReferralStatsEntity>((ref) async {
  return ref.watch(referralRemoteDataSourceProvider).fetchEarnings();
});

final referralLedgerProvider = FutureProvider<List<ReferralLedgerEntryEntity>>((ref) async {
  return ref.watch(referralRemoteDataSourceProvider).fetchLedger();
});
