import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/voice_room_entity.dart';
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

final voiceRoomsProvider = FutureProvider<List<VoiceRoomEntity>>((ref) async {
  return ref.watch(liveRepositoryProvider).fetchVoiceRooms();
});

final voiceRoomByIdProvider =
    FutureProvider.autoDispose.family<VoiceRoomEntity?, String>((ref, id) async {
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
