import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feed/domain/entities/post_entity.dart';
import '../../domain/entities/create_social_post_input.dart';
import 'social_providers.dart';

final socialCreatePostProvider =
    AsyncNotifierProvider<SocialCreatePostNotifier, void>(
  SocialCreatePostNotifier.new,
);

class SocialCreatePostNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<PostEntity> submit(CreateSocialPostInput input) async {
    state = const AsyncValue.loading();
    try {
      final post =
          await ref.read(socialRepositoryProvider).createPost(input);
      state = const AsyncValue.data(null);
      await ref.read(socialNotifierProvider.notifier).refresh();
      return post;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
