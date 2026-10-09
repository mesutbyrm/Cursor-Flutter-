import 'package:canlifal_social/features/social_accounts/data/social_accounts_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Dio _dio(void Function(RequestOptions o) onReq, dynamic body) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) {
        onReq(o);
        h.resolve(Response(requestOptions: o, statusCode: 200, data: body));
      },
    ),
  );
  return dio;
}

void main() {
  test('herkese açık liste: yalnız http(s) bağlantılı hesaplar', () async {
    final repo = SocialAccountsRepository(
      _dio((_) {}, {
        'accounts': [
          {'platform': 'instagram', 'label': 'Instagram', 'handle': 'canlifal', 'url': 'https://instagram.com/canlifal'},
          {'platform': 'x', 'label': 'X', 'url': 'javascript:alert(1)'},
        ],
      }),
    );
    final list = await repo.fetchPublic();
    expect(list.map((a) => a.platform), ['instagram']);
    expect(list.single.url, 'https://instagram.com/canlifal');
  });

  test('admin kaydı tüm platformları PUT ile gönderir', () async {
    RequestOptions? sent;
    final repo = SocialAccountsRepository(
      _dio((o) => sent = o, {
        'success': true,
        'accounts': [
          {'platform': 'tiktok', 'value': '@canlifal', 'url': 'https://www.tiktok.com/@canlifal', 'enabled': true},
        ],
      }),
    );
    final saved = await repo.saveAdmin([
      (platform: 'tiktok', value: ' @canlifal ', enabled: true),
      (platform: 'x', value: '', enabled: false),
    ]);
    expect(sent?.method, 'PUT');
    expect(sent?.path, '/api/admin/social-accounts');
    final accounts = (sent?.data as Map)['accounts'] as List;
    expect(accounts.first, {'platform': 'tiktok', 'value': '@canlifal', 'enabled': true});
    expect(saved.single.value, '@canlifal');
  });

  test('platform etiketi ve simgesi', () {
    expect(socialPlatformLabel('whatsapp'), 'WhatsApp');
    expect(socialPlatformLabel('bilinmeyen'), 'bilinmeyen');
  });
}
