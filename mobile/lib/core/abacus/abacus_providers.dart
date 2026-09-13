import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';
import 'abacus_api_bridge.dart';

final abacusApiBridgeProvider = Provider<AbacusApiBridge>(
  (ref) => AbacusApiBridge(ref.watch(dioProvider)),
);
