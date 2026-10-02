import 'package:canlifal_social/features/social/presentation/widgets/instagram/social_expandable_caption.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(String text, {int maxLines = 4}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 300,
            child: SocialExpandableCaption(
              text: text,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('kısa metinde "Daha fazla" yok', (tester) async {
    await tester.pumpWidget(_host('Merhaba dünya'));
    expect(find.text('Merhaba dünya'), findsOneWidget);
    expect(find.text('Daha fazla'), findsNothing);
  });

  testWidgets('uzun metin kesilir, Daha fazla ile tamamı açılır', (tester) async {
    // Test fontu (Ahem) geniştir; kısa tutulur ki "Daha az" ekranda kalsın.
    final long = List.filled(14, 'kelime').join(' ');
    await tester.pumpWidget(_host(long, maxLines: 2));
    final collapsed = tester.getSize(find.byType(SocialExpandableCaption)).height;
    expect(find.text('Daha fazla'), findsOneWidget);

    await tester.tap(find.text('Daha fazla'));
    await tester.pump();
    final expanded = tester.getSize(find.byType(SocialExpandableCaption)).height;
    expect(expanded, greaterThan(collapsed));
    expect(find.text('Daha az'), findsOneWidget);

    await tester.tap(find.text('Daha az'));
    await tester.pump();
    expect(find.text('Daha fazla'), findsOneWidget);
  });

  test('exceeds: satır sınırına göre ölçer', () {
    const style = TextStyle(fontSize: 15);
    expect(
      SocialExpandableCaption.exceeds(
        text: 'kısa',
        style: style,
        maxLines: 2,
        maxWidth: 200,
      ),
      isFalse,
    );
    expect(
      SocialExpandableCaption.exceeds(
        text: List.filled(80, 'uzun').join(' '),
        style: style,
        maxLines: 2,
        maxWidth: 200,
      ),
      isTrue,
    );
  });
}
