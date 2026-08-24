import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../data/datasources/room_music_remote_datasource.dart';
import '../../data/repositories/room_music_repository_impl.dart';
import '../../domain/repositories/room_music_repository.dart';
import '../../domain/usecases/control_playback_usecase.dart';
import '../../domain/usecases/enqueue_song_usecase.dart';
import '../../domain/usecases/resolve_stream_usecase.dart';
import '../../domain/usecases/search_music_usecase.dart';

import '../../data/datasources/room_song_remote_datasource.dart';
import '../bloc/room_song_bloc.dart';
import '../bloc/room_song_event.dart';

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

final roomSongRemoteDataSourceProvider = Provider<RoomSongRemoteDataSource>(
  (ref) => RoomSongRemoteDataSource(ref.watch(dioProvider)),
);

final roomSongBlocProvider = Provider.autoDispose.family<RoomSongBloc, String>(
  (ref, roomId) {
    final id = roomId.trim();
    final bloc = RoomSongBloc(ref.watch(roomSongRemoteDataSourceProvider));
    ref.onDispose(bloc.close);
    if (id.isNotEmpty) {
      bloc.add(RoomSongJoinSync(id));
    }
    return bloc;
  },
);
