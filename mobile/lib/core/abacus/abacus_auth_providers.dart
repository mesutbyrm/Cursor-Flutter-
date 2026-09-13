import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import 'abacus_auth_remote_datasource.dart';

final abacusAuthRemoteProvider = Provider<AbacusAuthRemoteDataSource>(
  (ref) => AbacusAuthRemoteDataSource(ref.watch(authRemoteDataSourceProvider)),
);
