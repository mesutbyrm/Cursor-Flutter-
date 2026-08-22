import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/data/datasources/mobile_compound_remote_datasource.dart';
import '../../domain/entities/fortune_type_entity.dart';

/// `GET /api/mobile/fortune-menu` — API fal türleri (yerel katalog yedeği).
final fortuneMenuTypesProvider =
    FutureProvider<List<FortuneTypeEntity>>((ref) async {
  final menu =
      await ref.watch(mobileCompoundRemoteProvider).fetchFortuneMenu();
  if (menu != null && menu.fortuneTypes.isNotEmpty) {
    return menu.fortuneTypes;
  }
  return const [];
});
