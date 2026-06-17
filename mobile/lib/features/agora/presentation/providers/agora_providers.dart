import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/agora_remote_datasource.dart';

final agoraRemoteProvider = Provider<AgoraRemoteDataSource>((ref) {
  return AgoraRemoteDataSource(ref.watch(dioProvider));
});
