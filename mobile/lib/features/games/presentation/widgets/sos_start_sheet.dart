import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/diagnostics/cf_diag.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/game_models.dart';
import '../../domain/game_state_parser.dart';
import '../providers/game_providers.dart';

bool isSosGame(GameCatalogItem game) =>
    GameStateParser.normalizeGameType(game.id) == 'sos';

/// SOS başlat — tahta boyutu (`grid-settings` → `sosGridSizes`) ve rakip
/// (yapay zekâ / arkadaş) seçilir, `POST /api/games/sos`, ardından
/// oluşan oyunun kimliği döner (vazgeçilir/hata olursa `null`).
Future<String?> createSosGameFlow(BuildContext context, WidgetRef ref) async {
  var settings = const GameGridSettings();
  try {
    settings = await ref.read(gameRemoteProvider).fetchGridSettings();
  } catch (e, st) {
    CfDiag.recordError(e, st, category: CfCategory.network);
  }
  if (!context.mounted) return null;
  final choice = await showModalBottomSheet<({int size, bool vsAi})>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _SosStartSheet(sizes: settings.sosSizes),
  );
  if (choice == null || !context.mounted) return null;
  try {
    return await ref
        .read(gameRemoteProvider)
        .createSosGame(gridSize: choice.size, vsAi: choice.vsAi);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
    return null;
  }
}

String sosGamePath(String id) => '/games-sos/${Uri.encodeComponent(id)}';

class _SosStartSheet extends StatefulWidget {
  const _SosStartSheet({required this.sizes});

  final List<int> sizes;

  @override
  State<_SosStartSheet> createState() => _SosStartSheetState();
}

class _SosStartSheetState extends State<_SosStartSheet> {
  late var _size = widget.sizes.first;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SOS — tahta boyutu',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final n in widget.sizes)
                  ChoiceChip(
                    label: Text('$n × $n'),
                    selected: n == _size,
                    onSelected: (_) => setState(() => _size = n),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(context, (size: _size, vsAi: true)),
              icon: const Icon(Icons.smart_toy_rounded),
              label: const Text('Yapay zekâya karşı'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pop(context, (size: _size, vsAi: false)),
              icon: const Icon(Icons.people_alt_rounded),
              label: const Text('Masa aç (rakip bekle)'),
            ),
          ],
        ),
      ),
    );
  }
}
