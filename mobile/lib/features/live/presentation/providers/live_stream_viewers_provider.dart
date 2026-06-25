import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_stream_viewer.dart';
import 'live_providers.dart';

final liveStreamViewersProvider =
    FutureProvider.autoDispose.family<List<LiveStreamViewer>, String>(
  (ref, streamId) async {
    final rows = await ref.read(liveRemoteProvider).fetchStreamViewers(streamId);
    return rows.map(LiveStreamViewer.fromJson).where((v) => v.id.isNotEmpty).toList();
  },
);
