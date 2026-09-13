import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';
import 'abacus_auth_remote_datasource.dart';

final abacusAuthRemoteProvider = Provider<AbacusAuthRemoteDataSource>(
  (ref) => AbacusAuthRemoteDataSource(ref.watch(dioProvider)),
);
