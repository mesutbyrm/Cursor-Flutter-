import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/moderation_remote_datasource.dart';
import '../../data/repositories/moderation_repository_impl.dart';
import '../../domain/repositories/moderation_repository.dart';

final moderationRemoteProvider = Provider<ModerationRemoteDataSource>((ref) {
  return ModerationRemoteDataSource(ref.watch(dioProvider));
});

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepositoryImpl(ref.watch(moderationRemoteProvider));
});
