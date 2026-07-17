import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../services/mobile_compound_service.dart';
import '../../domain/entities/fortune_type_entity.dart';

final mobileCompoundServiceProvider = Provider<MobileCompoundService>((ref) {
  return MobileCompoundService(ref.watch(dioProvider));
});

/// `GET /api/mobile/fortune-menu` — API fal türleri (yerel katalog yedeği).
final fortuneMenuTypesProvider =
    FutureProvider<List<FortuneTypeEntity>>((ref) async {
  final menu = await ref.watch(mobileCompoundServiceProvider).fetchFortuneMenu();
  if (menu != null && menu.fortuneTypes.isNotEmpty) {
    return menu.fortuneTypes;
  }
  return const [];
});
