import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/home/data/datasources/mobile_compound_remote_datasource.dart';
import 'package:canlifal_social/features/profile/data/datasources/canlifal_user_api_datasource.dart';
import 'package:canlifal_social/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:canlifal_social/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:canlifal_social/features/profile/domain/entities/profile_stats_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileRepositoryImpl.myStats', () {
    test('GET /api/user/stats failure is not a zeroed dashboard', () async {
      final repo = ProfileRepositoryImpl(
        _ThrowingStatsRemote(),
        CanlifalUserApiDataSource(Dio()),
      );

      await expectLater(
        repo.myStats(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('returns live stats when the kılavuz path succeeds', () async {
      final repo = ProfileRepositoryImpl(
        _OkStatsRemote(),
        CanlifalUserApiDataSource(Dio()),
      );

      final stats = await repo.myStats();
      expect(stats.earningsJeton, 12);
      expect(stats.followers, 3);
    });
  });
}

class _ThrowingStatsRemote extends ProfileRemoteDataSource {
  _ThrowingStatsRemote() : super(Dio(), MobileCompoundRemoteDataSource(Dio()));

  @override
  Future<ProfileStatsEntity> myStats() async {
    throw const ApiException('İstatistikler yüklenemedi', statusCode: 503);
  }

  @override
  Future<UserEntity> mySiteProfile() async =>
      const UserEntity(id: 'u1', username: 'u1', followersCount: 9);

  @override
  Future<List<BroadcastHistoryItemEntity>> broadcastHistory() async => const [];

  @override
  Future<int> profileVisitorCount() async => 0;
}

class _OkStatsRemote extends ProfileRemoteDataSource {
  _OkStatsRemote() : super(Dio(), MobileCompoundRemoteDataSource(Dio()));

  @override
  Future<ProfileStatsEntity> myStats() async {
    return const ProfileStatsEntity(earningsJeton: 12, followers: 3);
  }

  @override
  Future<UserEntity> mySiteProfile() async =>
      const UserEntity(id: 'u1', username: 'u1', followersCount: 9);

  @override
  Future<List<BroadcastHistoryItemEntity>> broadcastHistory() async => const [];

  @override
  Future<int> profileVisitorCount() async => 4;
}
