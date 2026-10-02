import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_broadcast_competition_rail_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('puan ve isim kısaltma', () {
    expect(formatCompetitionScore(950), '950');
    expect(formatCompetitionScore(12400), '12.4K');
    expect(formatCompetitionScore(2500000), '2.5M');
    expect(shortCompetitionName('Ayşe'), 'Ayşe');
    expect(shortCompetitionName('Abdurrahman'), 'Abdurr…');
  });

  testWidgets('kart: başlık + puan satırı gösterir, dokunulur', (t) async {
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveCompetitionRailCard(
            icon: Icons.emoji_events_outlined,
            title: 'Haftalık',
            line: '1. Selin 12.4K',
            color: Colors.amber,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text('Haftalık'), findsOneWidget);
    expect(find.text('1. Selin 12.4K'), findsOneWidget);
    await t.tap(find.text('Haftalık'));
    expect(taps, 1);
  });
}
