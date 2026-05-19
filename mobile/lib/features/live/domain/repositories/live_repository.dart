import '../entities/live_stream_entity.dart';

abstract class LiveRepository {
  Future<List<LiveStreamEntity>> fetchStreams({int page});
}
