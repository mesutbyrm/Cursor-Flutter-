import 'package:canlifal_social/features/social/data/datasources/social_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fal paylaşım açıklaması @kullanıcı ve hashtag içerir', () {
    final c = SocialRemoteDataSource.buildFortuneShareCaption(
      title: 'Tarot Falı',
      body: 'Yeni bir başlangıç seni bekliyor.',
      username: '@ayse',
    );
    expect(c, startsWith('🔮 @ayse Tarot Falı baktırdı ✨'));
    expect(c, contains('#TarotFalı'));
    expect(c, contains('#GirLive'));
  });

  test('biçimlenmiş metne hashtag eklenir, başlık tekrarlanmaz', () {
    final c = SocialRemoteDataSource.buildFortuneShareCaption(
      title: 'Kahve Falı',
      body: '🔮 Kahve falı yorumu',
    );
    expect('🔮'.allMatches(c).length, 1);
    expect(c, contains('#KahveFalı'));
  });
}
