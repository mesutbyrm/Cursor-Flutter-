import '../entities/live_stream_entity.dart';

abstract class LiveRepository {
  Future<List<LiveStreamEntity>> fetchStreams({int page = 1, String? category});

  Future<String> createVideoStream({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
    String? thumbnailUrl,
    bool isPrivate = false,
    bool isImageMode = false,
    String? backgroundUrl,
  });

  Future<void> endVideoStream(String streamId);

  Future<int> joinVideoStream(String streamId);

  Future<void> leaveVideoStream(String streamId);
}
