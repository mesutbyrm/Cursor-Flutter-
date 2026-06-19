import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../agency/data/datasources/agency_remote_datasource.dart';
import '../../../live_psychics/data/repositories/live_psychics_remote_datasource.dart';
import '../../../live_psychics/presentation/providers/live_psychics_providers.dart';
import '../../data/role_panel_resolver.dart';

final rolePanelResolverProvider = Provider<RolePanelResolver>((ref) {
  final dio = ref.watch(dioProvider);
  return RolePanelResolver(
    dio,
    ref.watch(livePsychicsRemoteProvider),
    AgencyRemoteDataSource(dio),
  );
});
