import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/diagnostics/cf_diag.dart';
import '../../domain/game_models.dart';
import '../../domain/game_state_parser.dart';
import '../providers/game_providers.dart';

/// XOX odası açılırken ızgara boyutu sorar (`GET /api/games/grid-settings`).
///
/// Dönen değer: XOX değilse `(proceed: true, size: null)`; kullanıcı
/// vazgeçerse `proceed: false`. Ayar okunamazsa sunucu varsayılanları
/// gösterilir (kayıt düşülür).
Future<({bool proceed, int? size})> pickGameGridSize(
  BuildContext context,
  WidgetRef ref,
  GameCatalogItem game,
) async {
  if (GameStateParser.normalizeGameType(game.id) != 'xox') {
    return (proceed: true, size: null);
  }
  var settings = const GameGridSettings();
  try {
    settings = await ref.read(gameRemoteProvider).fetchGridSettings();
  } catch (e, st) {
    CfDiag.recordError(e, st, category: CfCategory.network);
  }
  if (!context.mounted) return (proceed: false, size: null);
  final size = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Tahta boyutu',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          for (final n in settings.xoxSizes)
            ListTile(
              leading: const Icon(Icons.grid_on_rounded),
              title: Text('$n × $n'),
              subtitle: Text(
                n <= 4 ? '$n tanesini yan yana diz' : '5 tanesini yan yana diz',
              ),
              onTap: () => Navigator.pop(ctx, n),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (size == null) return (proceed: false, size: null);
  return (proceed: true, size: size);
}
