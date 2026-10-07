import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/core/navigation/native_site_routes.dart';
import 'package:canlifal_social/features/content_detail/data/content_detail_remote_datasource.dart';
import 'package:canlifal_social/features/content_detail/domain/content_detail_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Yol → yanıt eşlemesi; son istek kaydedilir.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.responses);

  final Map<String, Object> responses;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = responses[options.path] ?? {'error': 'yok'};
    return ResponseBody.fromString(
      jsonEncode(body),
      responses.containsKey(options.path) ? 200 : 404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ContentDetailRemoteDataSource _remote(_Adapter a) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = a;
  return ContentDetailRemoteDataSource(dio);
}

void main() {
  test('blog yazısı: ?slug= ile {post} okunur, titleTr/contentTr eşlenir', () async {
    final a = _Adapter({
      '/api/blog': {
        'post': {
          'id': 'p1',
          'slug': 'ay-burclari',
          'titleTr': 'Ay Burcunuz',
          'contentTr': 'Metin',
          'readTime': 5,
          'likes': 3,
          'publishedAt': '2026-01-02T10:00:00.000Z',
        },
      },
    });
    final post = await _remote(a).fetchBlogPost('ay-burclari');
    expect(a.requests.single.queryParameters['slug'], 'ay-burclari');
    expect(post.id, 'p1');
    expect(post.title, 'Ay Burcunuz');
    expect(post.content, 'Metin');
    expect(post.readTime, 5);
    expect(post.likes, 3);
    expect(post.publishedAt, isNotNull);
  });

  test('ilgili yazılar + burç yazıları {posts}; slug boş satır atılır', () async {
    final a = _Adapter({
      '/api/blog/related': {
        'posts': [
          {'id': '1', 'slug': 'a', 'titleTr': 'A'},
          {'id': '2', 'slug': '', 'titleTr': 'Boş'},
        ],
      },
      '/api/blog/zodiac': {
        'posts': [
          {'id': '3', 'slug': 'koc-1', 'titleTr': 'Koç'},
        ],
        'sign': 'koc',
      },
    });
    final r = _remote(a);
    final related = await r.fetchRelatedPosts('x');
    expect(related.map((p) => p.slug), ['a']);
    expect(a.requests.last.queryParameters, {'slug': 'x', 'limit': 4});
    final zodiac = await r.fetchZodiacPosts('koc');
    expect(zodiac.single.title, 'Koç');
    expect(a.requests.last.queryParameters['sign'], 'koc');
  });

  test('burç listesi: sayılar ve Türkçe etiket', () async {
    final a = _Adapter({
      '/api/blog/zodiac': {
        'signs': [
          {'sign': 'koc', 'totalPosts': 2, 'latestPost': {'titleTr': 'Son'}},
          {'sign': 'balik', 'totalPosts': 0, 'latestPost': null},
        ],
      },
    });
    final signs = await _remote(a).fetchZodiacSigns();
    expect(signs.first.label, 'Koç');
    expect(signs.first.totalPosts, 2);
    expect(signs.first.latestTitle, 'Son');
    expect(signs.last.label, 'Balık');
  });

  test('beğeni/favori: POST {postId}, aç/kapa sonucu okunur', () async {
    final a = _Adapter({
      '/api/blog/like': {'liked': true},
      '/api/blog/favorite': {'favorited': false},
      '/api/blog/interactions': {
        'liked': true,
        'favorited': false,
        'likesCount': 7,
      },
    });
    final r = _remote(a);
    expect(await r.toggleLike('p1'), isTrue);
    expect(a.requests.last.method, 'POST');
    expect(a.requests.last.data, {'postId': 'p1'});
    expect(await r.toggleFavorite('p1'), isFalse);
    final s = await r.fetchInteractions('p1');
    expect(a.requests.last.queryParameters['postId'], 'p1');
    expect(s.liked, isTrue);
    expect(s.likesCount, 7);
  });

  test('rüya sembolü: slug yolda kodlanır, ilgili semboller eşlenir', () async {
    final a = _Adapter({
      '/api/dream-symbols/y%C4%B1lan': {
        'name': 'Yılan',
        'slug': 'yılan',
        'meaning': 'Gizli düşman',
        'detailedMeaning': 'Uzun',
        'relatedDreams': [
          {'name': 'Akrep', 'slug': 'akrep'},
          {'name': '', 'slug': 'bos'},
        ],
      },
    });
    final s = await _remote(a).fetchDreamSymbol('yılan');
    expect(a.requests.single.path, '/api/dream-symbols/y%C4%B1lan');
    expect(s.name, 'Yılan');
    expect(s.related.map((r) => r.slug), ['akrep']);
  });

  test('TikTok: liste {videos}, detay {video, related}; yalnız https dış bağlantı', () async {
    final a = _Adapter({
      '/api/tiktok-videos': {
        'videos': [
          {
            'id': 'v1',
            'tiktokUrl': 'https://www.tiktok.com/@a/video/1',
            'category': {'title': 'Komik'},
          },
        ],
        'categories': [],
      },
      '/api/tiktok-videos/v1': {
        'video': {
          'id': 'v1',
          'tiktokUrl': 'https://www.tiktok.com/@a/video/1',
          'title': 'Başlık',
        },
        'related': [
          {'id': 'v2', 'tiktokUrl': 'javascript:alert(1)'},
        ],
      },
    });
    final r = _remote(a);
    final list = await r.fetchTiktokVideos();
    expect(list.single.categoryTitle, 'Komik');
    expect(list.single.displayTitle, 'TikTok videosu');
    final d = await r.fetchTiktokVideo('v1');
    expect(d.video.displayTitle, 'Başlık');
    expect(d.video.externalUri?.host, 'www.tiktok.com');
    expect(d.related.single.externalUri, isNull);
  });

  test('unwrapContentBody {success,data} zarfını açar', () {
    expect(
      unwrapContentBody({
        'success': true,
        'data': {'posts': []},
      }),
      {'posts': []},
    );
    expect(unwrapContentBody({'post': 1}), {'post': 1});
  });

  group('nativeContentDetailPath', () {
    test('web içerik yolları native sayfaya gider', () {
      expect(nativeContentDetailPath('/blog/ay-burclari'), '/blog/ay-burclari');
      expect(nativeContentDetailPath('/blog/burclar'), '/blog/burclar');
      expect(nativeContentDetailPath('/ruya-sozlugu/yilan'), '/ruya-sozlugu/yilan');
      expect(nativeContentDetailPath('/tiktok'), '/tiktok');
      expect(nativeContentDetailPath('/tiktok/abc'), '/tiktok/abc');
    });

    test('hub ve desteklenmeyen alt yollar eski davranışta kalır', () {
      expect(nativeContentDetailPath('/blog'), isNull);
      expect(nativeContentDetailPath('/blog-hub'), isNull);
      expect(nativeContentDetailPath('/blog/kategori'), isNull);
      expect(nativeContentDetailPath('/blog/kategori/astro'), isNull);
      expect(nativeContentDetailPath('/ruya-sozlugu'), isNull);
      expect(nativeContentDetailPath('/ruya/yilan'), isNull);
    });
  });
}
