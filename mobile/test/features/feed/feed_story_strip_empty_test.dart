import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/feed/domain/entities/post_entity.dart';
import 'package:canlifal_social/features/feed/presentation/widgets/feed_story_strip.dart';

/// Gerçek gönderi yokken şerit, uydurma kullanıcılar ('Özge', 'Ela', 'Arda' —
/// i.pravatar.cc avatarlarıyla) gösteriyordu: var olmayan kişiler gerçekmiş
/// gibi sunuluyordu. Artık hikâye yoksa şerit hiç çizilmiyor.
void main() {
  PostEntity post({
    required String id,
    required String name,
    String? caption,
    String? authorId,
  }) {
    return PostEntity(
      id: id,
      caption: caption,
      author: UserEntity(
        id: authorId ?? 'u-$id',
        username: name,
        displayName: name,
      ),
    );
  }

  Future<void> pump(WidgetTester tester, List<PostEntity> posts) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: FeedStoryStrip(posts: posts))),
    );
  }

  testWidgets('gönderi yokken uydurma kullanıcı göstermez', (tester) async {
    await pump(tester, const []);

    expect(find.text('Özge'), findsNothing);
    expect(find.text('Ela'), findsNothing);
    expect(find.text('Arda'), findsNothing);
    expect(find.byType(ListView), findsNothing, reason: 'şerit çizilmemeli');
  });

  testWidgets('yalnızca fal içerikli gönderiler varken de şerit çizilmez',
      (tester) async {
    await pump(tester, [
      post(id: '1', name: 'Ayse', caption: 'kahve falı baktırdım'),
    ]);

    expect(find.text('Ayse'), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('gerçek gönderi varken yazarını gösterir', (tester) async {
    await pump(tester, [
      post(id: '1', name: 'Ayse', caption: 'merhaba'),
      post(id: '2', name: 'Kerem', caption: 'günaydın'),
    ]);

    expect(find.text('Ayse'), findsOneWidget);
    expect(find.text('Kerem'), findsOneWidget);
  });

  testWidgets('aynı yazarı tekrar göstermez', (tester) async {
    await pump(tester, [
      post(id: '1', name: 'Ayse', caption: 'bir', authorId: 'u-ayse'),
      post(id: '2', name: 'Ayse', caption: 'iki', authorId: 'u-ayse'),
    ]);

    expect(find.text('Ayse'), findsOneWidget);
  });
}
