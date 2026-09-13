import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';
import 'me_entitlements_remote_datasource.dart';

final meEntitlementsRemoteProvider = Provider<MeEntitlementsRemoteDataSource>(
  (ref) => MeEntitlementsRemoteDataSource(ref.watch(dioProvider)),
);

final meMembershipPackageProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(meEntitlementsRemoteProvider).fetchMembership(),
);
