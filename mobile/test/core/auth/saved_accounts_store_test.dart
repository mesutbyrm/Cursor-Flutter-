import 'package:canlifal_social/core/auth/saved_accounts_store.dart';
import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

UserEntity _user(String id) => UserEntity(
      id: id,
      username: 'user_$id',
      displayName: 'Kullanıcı $id',
    );

Future<void> _login(TokenStorage tokens, String id) =>
    tokens.writeTokens(access: 'access-$id', refresh: 'refresh-$id', userId: id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterSecureStorage storage;
  late SavedAccountsStore store;
  late TokenStorage tokens;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    store = SavedAccountsStore(storage);
    tokens = TokenStorage(storage);
  });

  test('aktif oturum kalıcı olarak kaydedilir ve geri okunur', () async {
    await _login(tokens, 'a');
    await store.upsertFromSession(user: _user('a'), tokens: tokens);

    final all = await SavedAccountsStore(storage).readAll();
    expect(all, hasLength(1));
    expect(all.single.userId, 'a');
    expect(all.single.username, 'user_a');
    expect(all.single.label, 'Kullanıcı a');
    expect(all.single.accessToken, 'access-a');
    expect(all.single.refreshToken, 'refresh-a');
  });

  test('en fazla 5 hesap tutulur; en yeni başta, en eski düşer', () async {
    for (final id in ['1', '2', '3', '4', '5', '6']) {
      await _login(tokens, id);
      await store.upsertFromSession(user: _user(id), tokens: tokens);
    }
    final all = await store.readAll();
    expect(maxSavedAccounts, 5);
    expect(all.map((e) => e.userId), ['6', '5', '4', '3', '2']);
  });

  test('canAddAnother 5 hesapta false olur', () async {
    for (final id in ['1', '2', '3', '4']) {
      await _login(tokens, id);
      await store.upsertFromSession(user: _user(id), tokens: tokens);
    }
    expect(await store.canAddAnother(), isTrue);
    await _login(tokens, '5');
    await store.upsertFromSession(user: _user('5'), tokens: tokens);
    expect(await store.canAddAnother(), isFalse);
  });

  test('aynı hesap tekrar kaydedilince çoğalmaz ve token güncellenir', () async {
    await _login(tokens, 'a');
    await store.upsertFromSession(user: _user('a'), tokens: tokens);
    await tokens.writeTokens(access: 'access-a2', refresh: 'refresh-a2');
    await store.upsertFromSession(user: _user('a'), tokens: tokens);

    final all = await store.readAll();
    expect(all, hasLength(1));
    expect(all.single.accessToken, 'access-a2');
    expect(all.single.refreshToken, 'refresh-a2');
  });

  test('remove boş listede hata vermez ve kaydı siler', () async {
    await store.remove('yok');
    await _login(tokens, 'a');
    await store.upsertFromSession(user: _user('a'), tokens: tokens);
    await store.remove('a');
    expect(await store.readAll(), isEmpty);
  });

  test('çerez oturumu işaretçisi hesap olarak kaydedilmez', () async {
    await tokens.writeTokens(access: TokenStorage.sessionCookieMarker);
    await store.upsertFromSession(user: _user('a'), tokens: tokens);
    expect(await store.readAll(), isEmpty);
  });
}
