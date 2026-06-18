import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../agency/data/datasources/agency_remote_datasource.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/role_panel_resolver.dart';

final rolePanelResolverProvider = Provider<RolePanelResolver>((ref) {
  final dio = ref.watch(dioProvider);
  return RolePanelResolver(
    dio,
    ref.watch(homeRemoteProvider),
    AgencyRemoteDataSource(dio),
  );
});
