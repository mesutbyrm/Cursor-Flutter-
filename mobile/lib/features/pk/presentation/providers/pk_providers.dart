import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/pk_service.dart';

final pkServiceProvider = Provider<PkService>((ref) {
  return PkService(ref.watch(dioProvider));
});
