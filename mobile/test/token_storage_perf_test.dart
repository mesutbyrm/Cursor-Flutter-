import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};
  var readCount = 0;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    readCount++;
    return _data[key];
  }

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

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  test('peekAccess and readAccess use memory after writeTokens', () async {
    final backing = _FakeSecureStorage();
    final storage = TokenStorage(backing);
    await storage.writeTokens(access: 'token-a');

    expect(storage.peekAccess(), 'token-a');
    expect(backing.readCount, 0);

    expect(await storage.readAccess(), 'token-a');
    expect(backing.readCount, 0);
  });

  test('readAccess hydrates from storage once', () async {
    final backing = _FakeSecureStorage();
    await backing.write(key: 'jwt_access_token', value: 'stored');
    final storage = TokenStorage(backing);

    expect(await storage.readAccess(), 'stored');
    expect(backing.readCount, 1);
    expect(storage.peekAccess(), 'stored');
    expect(await storage.readAccess(), 'stored');
    expect(backing.readCount, 1);
  });

  test('clear resets memory cache', () async {
    final storage = TokenStorage(_FakeSecureStorage());
    await storage.writeTokens(access: 'token-a');
    await storage.clear();

    expect(storage.peekAccess(), isNull);
    expect(await storage.readAccess(), isNull);
  });
}
