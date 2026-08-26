import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/pagination/paged_result.dart';
import 'package:canlifal_social/features/games/data/game_remote_datasource.dart';
import 'package:canlifal_social/features/games/data/repositories/game_center_repository_impl.dart';
import 'package:canlifal_social/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:canlifal_social/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:canlifal_social/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:canlifal_social/features/profile/data/datasources/canlifal_user_api_datasource.dart';
import 'package:canlifal_social/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:canlifal_social/features/profile/domain/entities/profile_stats_entity.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';
import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationsRepositoryImpl.fetch', () {
    test('GET /api/notifications failure is not an empty inbox', () async {
      final repo = NotificationsRepositoryImpl(
        _ThrowingNotificationsRemote(),
        _EmptyActivityRemote(),
      );

      await expectLater(
        repo.fetch(forceRefresh: true),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('successful list still returns items', () async {
      final repo = NotificationsRepositoryImpl(
        _OkNotificationsRemote(),
        _EmptyActivityRemote(),
      );

      final items = await repo.fetch(forceRefresh: true);
      expect(items, hasLength(1));
      expect(items.single.id, 'n1');
    });
  });

  group('GameCenterRepositoryImpl.fetchJetonBalance', () {
    test('does not report 0 when wallet fails', () async {
      final repo = GameCenterRepositoryImpl(
        games: GameRemoteDataSource(Dio()),
        wallet: _FailingWallet(),
      );

      await expectLater(
        repo.fetchJetonBalance(),
        throwsA(isA<ApiException>()),
      );
    });

    test('returns live jeton balance', () async {
      final repo = GameCenterRepositoryImpl(
        games: GameRemoteDataSource(Dio()),
        wallet: _OkWallet(),
      );

      expect(await repo.fetchJetonBalance(), 42);
    });
  });
}

class _ThrowingNotificationsRemote extends NotificationsRemoteDataSource {
  _ThrowingNotificationsRemote() : super(Dio());

  @override
  Future<List<AppNotificationEntity>> list() async {
    throw const ApiException('Bildirimler yüklenemedi', statusCode: 503);
  }
}

class _OkNotificationsRemote extends NotificationsRemoteDataSource {
  _OkNotificationsRemote() : super(Dio());

  @override
  Future<List<AppNotificationEntity>> list() async {
    return const [
      AppNotificationEntity(id: 'n1', title: 'Test', read: false),
    ];
  }
}

class _EmptyActivityRemote extends CanlifalUserApiDataSource {
  _EmptyActivityRemote() : super(Dio());

  @override
  Future<PagedResult<ProfileActivityItemEntity>> fetchActivity({
    bool unreadOnly = false,
    int page = 1,
    int limit = 30,
  }) async {
    return const PagedResult(items: [], hasMore: false);
  }
}

class _FailingWallet extends WalletRemoteDataSource {
  _FailingWallet() : super(Dio(), TokenStorage(const FlutterSecureStorage()));

  @override
  Future<WalletBalances> balances({bool forceRefresh = false}) async {
    throw const ApiException('Bakiye alınamadı', statusCode: 503);
  }
}

class _OkWallet extends WalletRemoteDataSource {
  _OkWallet() : super(Dio(), TokenStorage(const FlutterSecureStorage()));

  @override
  Future<WalletBalances> balances({bool forceRefresh = false}) async {
    return const WalletBalances(jeton: 42);
  }
}
