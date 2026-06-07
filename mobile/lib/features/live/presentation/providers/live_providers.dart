import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/voice_room_entity.dart';
import '../../domain/repositories/live_repository.dart';
import '../../data/datasources/live_remote_datasource.dart';
import '../../data/datasources/live_stream_extras_datasource.dart';
import '../../data/repositories/live_repository_impl.dart';
import '../../data/services/video_webrtc_signal_service.dart';

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

final liveRepositoryProvider = Provider<LiveRepository>((ref) {
  return LiveRepositoryImpl(ref.watch(liveRemoteProvider));
});

final liveStreamsProvider = FutureProvider<List<LiveStreamEntity>>((ref) async {
  return ref.watch(liveRepositoryProvider).fetchStreams(page: 1);
});

final voiceRoomsProvider = FutureProvider<List<VoiceRoomEntity>>((ref) async {
  return ref.watch(liveRepositoryProvider).fetchVoiceRooms();
});

final voiceRoomByIdProvider =
    FutureProvider.autoDispose.family<VoiceRoomEntity?, String>((ref, id) async {
  final needle = id.trim().toLowerCase();
  if (needle.isEmpty) return null;
  final cached = ref.watch(voiceRoomsProvider).valueOrNull;
  if (cached != null) {
    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'-+$'), '');
    for (final r in cached) {
      if (r.id == id ||
          r.slug == id ||
          r.id.toLowerCase() == needle ||
          r.slug.toLowerCase() == needle ||
          norm(r.slug) == norm(id) ||
          norm(r.id) == norm(id)) {
        return r;
      }
    }
  }
  return ref.watch(liveRepositoryProvider).fetchVoiceRoomById(id);
});

/// Giriş yapan kullanıcının sahip olduğu sesli oda (ownerId veya slug = username).
final myVoiceRoomProvider = Provider<VoiceRoomEntity?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final rooms = ref.watch(voiceRoomsProvider).valueOrNull;
  if (user == null || rooms == null || rooms.isEmpty) return null;

  for (final r in rooms) {
    final oid = r.ownerId;
    if (oid != null && oid.isNotEmpty && oid == user.id) return r;
  }
  final uname = user.username.trim().toLowerCase();
  if (uname.isEmpty) return null;
  for (final r in rooms) {
    if (r.slug.trim().toLowerCase() == uname) return r;
  }
  return null;
});
