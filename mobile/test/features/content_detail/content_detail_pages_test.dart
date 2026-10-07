import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/features/content_detail/data/content_detail_remote_datasource.dart';
import 'package:canlifal_social/features/content_detail/domain/content_detail_models.dart';
import 'package:canlifal_social/features/content_detail/presentation/pages/blog_post_page.dart';
import 'package:canlifal_social/features/content_detail/presentation/pages/dream_symbol_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = switch (options.path) {
      '/api/blog/interactions' => {
          'liked': true,
          'favorited': false,
          'likesCount': 9,
        },
      '/api/blog/like' => {'liked': false},
      _ => <String, Object>{},
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Widget _wrap(Widget child, List<Override> overrides) => ProviderScope(
      overrides: [
        contentDetailRemoteProvider.overrideWithValue(
          ContentDetailRemoteDataSource(
            Dio(BaseOptions(baseUrl: 'https://example.test'))
              ..httpClientAdapter = _Adapter(),
          ),
        ),
        ...overrides,
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('blog yazısı: içerik, beğeni durumu ve ilgili yazılar', (t) async {
    await t.pumpWidget(_wrap(const BlogPostPage(slug: 's'), [
      blogPostProvider('s').overrideWith(
        (ref) async => const BlogPostItem(
          id: 'p1',
          slug: 's',
          title: 'Başlık',
          content: 'Yazı gövdesi',
          likes: 2,
        ),
      ),
      blogRelatedProvider('s').overrideWith(
        (ref) async => const [
          BlogPostItem(id: 'p2', slug: 'diger', title: 'Diğer yazı'),
        ],
      ),
    ]));
    await t.pumpAndSettle();
    expect(find.text('Yazı gövdesi'), findsOneWidget);
    expect(find.text('Diğer yazı'), findsOneWidget);
    // Sunucu durumu: beğenildi, 9 beğeni.
    expect(find.text('9'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    // Dokununca sunucu `liked:false` → sayaç düşer.
    await t.tap(find.text('9'));
    await t.pumpAndSettle();
    expect(find.text('8'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });

  testWidgets('rüya sembolü: anlam ve ilgili semboller', (t) async {
    await t.pumpWidget(_wrap(const DreamSymbolPage(slug: 'yilan'), [
      dreamSymbolProvider('yilan').overrideWith(
        (ref) async => const DreamSymbolDetail(
          name: 'Yılan',
          slug: 'yilan',
          meaning: 'Gizli düşman',
          related: [(name: 'Akrep', slug: 'akrep')],
        ),
      ),
    ]));
    await t.pumpAndSettle();
    expect(find.text('Gizli düşman'), findsOneWidget);
    expect(find.text('Akrep'), findsOneWidget);
  });
}
