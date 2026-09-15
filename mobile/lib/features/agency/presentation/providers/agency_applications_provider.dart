import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/agency_entity.dart';
import 'agency_providers.dart';

final agencyMemberApplicationsProvider =
    FutureProvider.autoDispose<List<AgencyMemberApplicationEntity>>((ref) async {
  return ref.read(agencyRemoteProvider).fetchMemberApplications();
});
