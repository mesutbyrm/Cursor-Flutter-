import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/repositories/live_repository.dart';
import '../../data/datasources/live_remote_datasource.dart';
import '../../data/repositories/live_repository_impl.dart';

final liveRemoteProvider = Provider<LiveRemoteDataSource>((ref) {
  return LiveRemoteDataSource(ref.watch(dioProvider));
});

final liveRepositoryProvider = Provider<LiveRepository>((ref) {
  return LiveRepositoryImpl(ref.watch(liveRemoteProvider));
});

final liveStreamsProvider = FutureProvider<List<LiveStreamEntity>>((ref) async {
  return ref.watch(liveRepositoryProvider).fetchStreams(page: 1);
});
