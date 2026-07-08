import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/repositories/live_psychics_remote_datasource.dart';
import '../../data/repositories/live_psychics_repository_impl.dart';
import '../../data/services/fortune_teller_profile_resolver.dart';
import '../../data/services/psychic_incoming_sse_service.dart';
import '../../data/services/psychic_room_sse_service.dart';
import '../../domain/entities/psychic_entity.dart';
import '../../domain/repositories/live_psychics_repository.dart';

/// Ana sayfa — çevrimiçi falcılar (bootstrap + section paylaşımlı cache).
final homeOnlinePsychicsProvider =
    FutureProvider<List<PsychicEntity>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(livePsychicsRepositoryProvider);
  final all = await repo.fetchPsychics(page: 1, limit: 20, onlineOnly: true);
  final online = all.where((p) => p.isOnline).toList();
  return online.isNotEmpty ? online : all;
});

final livePsychicsRemoteProvider = Provider<LivePsychicsRemoteDataSource>((ref) {
  return LivePsychicsRemoteDataSource(ref.watch(dioProvider));
});

final fortuneTellerProfileResolverProvider =
    Provider<FortuneTellerProfileResolver>((ref) {
  return FortuneTellerProfileResolver(
    ref.watch(dioProvider),
    ref.watch(livePsychicsRemoteProvider),
  );
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
