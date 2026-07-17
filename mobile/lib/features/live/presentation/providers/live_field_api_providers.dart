import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/live_field/live_field_api_remote_datasource.dart';

/// 7 saha `/api/live/*` API — Riverpod erişimi.
final liveFieldApiRemoteProvider = Provider<LiveFieldApiRemoteDataSource>((ref) {
  return LiveFieldApiRemoteDataSource(ref.watch(dioProvider));
});
