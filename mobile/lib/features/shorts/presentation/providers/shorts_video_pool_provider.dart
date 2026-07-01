import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/shorts_video_controller_pool.dart';

final shortsVideoPoolProvider = Provider.autoDispose<ShortsVideoControllerPool>(
  (ref) {
    final pool = ShortsVideoControllerPool(ref.watch(dioProvider));
    ref.onDispose(pool.disposeAll);
    return pool;
  },
);
