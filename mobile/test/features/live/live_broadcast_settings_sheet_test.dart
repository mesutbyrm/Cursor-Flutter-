import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_broadcast_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ayar sheet: eylemler, anahtarlar ve Yayını Bitir', (t) async {
    var ended = 0;
    await t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showLiveBroadcastSettingsSheet(
                    context: context,
                    ref: ref,
                    hostName: 'Selin',
                    onBeautyFilter: () {},
                    onShare: () {},
                    onEndBroadcast: () => ended++,
                  ),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('aç'));
    await t.pumpAndSettle();

    expect(find.text('Selin'), findsOneWidget);
    for (final l in [
      'Güzellik Efektleri ve Filtreler',
      'Paylaş',
      'Misafir Kabul Et',
      'Yorumlar',
      'Hediyeler',
      'Yayını Bitir',
    ]) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
    // Backend karşılığı olmayan anahtarlar uydurulmadı.
    expect(find.text('Oda Şifresi'), findsNothing);

    await t.tap(find.text('Yayını Bitir'));
    await t.pumpAndSettle();
    expect(ended, 1);
  });
}
