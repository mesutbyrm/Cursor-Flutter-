import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/games/domain/game_models.dart';
import 'package:canlifal_social/features/games/presentation/widgets/game_catalog_assets.dart';

void main() {
  test('katalogdaki her oyunun yerel kapağı var ve dosyası mevcut', () {
    final missing = <String>[];
    for (final g in GameCatalogFallback.all) {
      final path = GameCatalogAssets.assetPath(g);
      if (path == null || !File(path).existsSync()) missing.add(g.id);
    }
    expect(missing, isEmpty, reason: 'kapağı olmayan oyunlar: $missing');
  });

  test('alt çizgili backend gameType tire\'li kapağa eşlenir', () {
    const g = GameCatalogItem(id: 'tas_kagit_makas', title: 'x', kind: GameKind.multiplayer);
    expect(GameCatalogAssets.assetPath(g), 'assets/games/tas-kagit-makas.webp');
  });
}
