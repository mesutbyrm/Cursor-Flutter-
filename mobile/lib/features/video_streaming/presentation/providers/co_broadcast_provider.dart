import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/co_broadcast_datasource.dart';
import '../../data/repositories/co_broadcast_repository_impl.dart';
import '../../domain/entities/co_broadcast_entity.dart';
import '../../domain/repositories/co_broadcast_repository.dart';
import '../../../../core/network/dio_provider.dart';

final coBroadcastDataSourceProvider = Provider<CoBroadcastDataSource>((ref) => CoBroadcastDataSourceImpl(dio: ref.watch(dioProvider)));

final coBroadcastRepositoryProvider = Provider<CoBroadcastRepository>((ref) => CoBroadcastRepositoryImpl(dataSource: ref.watch(coBroadcastDataSourceProvider)));

final coBroadcastProvider = FutureProvider.family<CoBroadcast, String>((ref, broadcastId) async => ref.watch(coBroadcastRepositoryProvider).getCoBroadcast(broadcastId));

final pendingRequestsProvider = FutureProvider.family<List<CoBroadcastRequest>, String>((ref, userId) async => ref.watch(coBroadcastRepositoryProvider).getPendingRequests(userId));

final selectedBroadcastProvider = StateProvider<CoBroadcast?>((ref) => null);
