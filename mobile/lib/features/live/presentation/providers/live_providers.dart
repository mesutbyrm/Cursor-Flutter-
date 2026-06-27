import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/repositories/live_repository.dart';
import '../../data/datasources/live_remote_datasource.dart';
import '../../data/datasources/live_stream_extras_datasource.dart';
import '../../data/repositories/live_repository_impl.dart';
import '../../data/services/video_webrtc_signal_service.dart';
import '../../data/services/video_stream_sse_service.dart';
import '../gifts/providers/live_gift_providers.dart';

final liveRemoteProvider = Provider<LiveRemoteDataSource>((ref) {
  return LiveRemoteDataSource(ref.watch(dioProvider));
});

final liveStreamExtrasProvider = Provider<LiveStreamExtrasDataSource>((ref) {
  return LiveStreamExtrasDataSource(ref.watch(dioProvider));
});

final videoWebrtcSignalServiceProvider =
    Provider<VideoWebrtcSignalService>((ref) {
  final s = VideoWebrtcSignalService(ref.watch(liveStreamExtrasProvider));
  ref.onDispose(s.dispose);
  return s;
});

final videoStreamSseServiceProvider = Provider<VideoStreamSseService>((ref) {
  final s = VideoStreamSseService(ref.watch(liveGiftsRemoteProvider));
  ref.onDispose(s.disconnect);
  return s;
});

final liveRepositoryProvider = Provider<LiveRepository>((ref) {
  return LiveRepositoryImpl(ref.watch(liveRemoteProvider));
});

final liveStreamsProvider = FutureProvider<List<LiveStreamEntity>>((ref) async {
  return ref.watch(liveRepositoryProvider).fetchStreams(page: 1);
});
