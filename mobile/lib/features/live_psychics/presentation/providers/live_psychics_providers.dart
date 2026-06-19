import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/repositories/live_psychics_remote_datasource.dart';
import '../../data/repositories/live_psychics_repository_impl.dart';
import '../../data/services/psychic_incoming_sse_service.dart';
import '../../data/services/psychic_room_sse_service.dart';
import '../../domain/repositories/live_psychics_repository.dart';

final livePsychicsRemoteProvider = Provider<LivePsychicsRemoteDataSource>((ref) {
  return LivePsychicsRemoteDataSource(ref.watch(dioProvider));
});

final livePsychicsRepositoryProvider = Provider<LivePsychicsRepository>((ref) {
  return LivePsychicsRepositoryImpl(ref.watch(livePsychicsRemoteProvider));
});

final psychicIncomingSseServiceProvider = Provider<PsychicIncomingSseService>((ref) {
  final service = PsychicIncomingSseService();
  ref.onDispose(service.disconnect);
  return service;
});

final psychicRoomSseServiceProvider = Provider<PsychicRoomSseService>((ref) {
  final service = PsychicRoomSseService();
  ref.onDispose(service.disconnect);
  return service;
});
