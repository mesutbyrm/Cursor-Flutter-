import 'package:canlifal_social/core/widgets/settings_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('kutucuk ızgarası iki sütun, dokunma ve anahtar çalışır',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var tapped = 0;
    var toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                children: [
                  SettingsTileGrid(
                    children: [
                      SettingsTileCard(
                        icon: Icons.person,
                        label: 'Profil',
                        subtitle: 'Düzenle',
                        onTap: () => tapped++,
                      ),
                      SettingsToggleTile(
                        icon: Icons.speed,
                        label: 'Performans',
                        value: toggled,
                        onChanged: (v) => setState(() => toggled = v),
                      ),
                      const SettingsTileCard(
                        icon: Icons.info,
                        label: 'Bilgi',
                      ),
                    ],
                  ),
                  const SettingsPanel(
                    title: 'Panel',
                    child: ListTile(title: Text('içerik')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final a = tester.getTopLeft(find.text('Profil'));
    final b = tester.getTopLeft(find.text('Performans'));
    expect(b.dx, greaterThan(a.dx), reason: 'iki kutucuk yan yana');

    await tester.tap(find.text('Profil'));
    expect(tapped, 1);
    await tester.tap(find.text('Performans'));
    await tester.pump();
    expect(toggled, isTrue);
    expect(tester.takeException(), isNull);
  });
}
