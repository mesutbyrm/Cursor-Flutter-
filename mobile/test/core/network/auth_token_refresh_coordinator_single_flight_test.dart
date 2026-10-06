import 'package:canlifal_social/core/network/auth_token_refresh_coordinator.dart';
import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthTokenRefreshCoordinator single-flight (Spec 1)', () {
    late TokenStorage storage;
    late Dio dio;
    var refreshPosts = 0;

    setUp(() async {
      refreshPosts = 0;
      final backing = _MemSecureStorage();
      await backing.write(key: 'jwt_refresh_token', value: 'refresh-1');
      storage = TokenStorage(backing);
      dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            refreshPosts++;
            await Future<void>.delayed(const Duration(milliseconds: 80));
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const {
                  'accessToken': 'access-new',
                  'refreshToken': 'refresh-new',
                },
              ),
            );
          },
        ),
      );
      AuthTokenRefreshCoordinator.instance.reset();
    });

    test('concurrent refreshLegacy performs one HTTP refresh', () async {
      final coord = AuthTokenRefreshCoordinator.instance;
      final results = await Future.wait([
        coord.refreshLegacy(refreshDio: dio, storage: storage),
        coord.refreshLegacy(refreshDio: dio, storage: storage),
        coord.refreshLegacy(refreshDio: dio, storage: storage),
      ]);

      expect(refreshPosts, 1);
      expect(results, everyElement(isTrue));
    });
  });
}
