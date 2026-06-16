import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../data/datasources/room_music_remote_datasource.dart';
import '../../data/repositories/room_music_repository_impl.dart';
import '../../domain/repositories/room_music_repository.dart';
import '../../domain/usecases/control_playback_usecase.dart';
import '../../domain/usecases/enqueue_song_usecase.dart';
import '../../domain/usecases/resolve_stream_usecase.dart';
import '../../domain/usecases/search_music_usecase.dart';

final roomMusicRemoteDataSourceProvider = Provider<RoomMusicRemoteDataSource>(
  (ref) => RoomMusicRemoteDataSource(ref.watch(dioProvider)),
);

final roomMusicRepositoryProvider = Provider<RoomMusicRepository>(
  (ref) => RoomMusicRepositoryImpl(
    ref.watch(roomMusicRemoteDataSourceProvider),
  ),
);

final searchMusicUseCaseProvider = Provider<SearchMusicUseCase>(
  (ref) => SearchMusicUseCase(ref.watch(roomMusicRepositoryProvider)),
);

final enqueueSongUseCaseProvider = Provider<EnqueueSongUseCase>(
  (ref) => EnqueueSongUseCase(ref.watch(roomMusicRepositoryProvider)),
);

final resolveStreamUseCaseProvider = Provider<ResolveStreamUseCase>(
  (ref) => ResolveStreamUseCase(ref.watch(roomMusicRepositoryProvider)),
);

final controlPlaybackUseCaseProvider = Provider<ControlPlaybackUseCase>(
  (ref) => ControlPlaybackUseCase(ref.watch(roomMusicRepositoryProvider)),
);
