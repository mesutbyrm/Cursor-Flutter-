import '../models/app_models.dart';
import 'app_repository.dart';

enum TrtcRole {
  anchor,
  audience,
  speaker,
  listener;

  String get apiValue => switch (this) {
    TrtcRole.anchor => 'anchor',
    TrtcRole.audience => 'audience',
    TrtcRole.speaker => 'speaker',
    TrtcRole.listener => 'listener',
  };
}

class TrtcJoinRequest {
  const TrtcJoinRequest({
    required this.userId,
    required this.roomId,
    required this.role,
    this.enableCamera = false,
    this.enableMicrophone = false,
  });

  final String userId;
  final String roomId;
  final TrtcRole role;
  final bool enableCamera;
  final bool enableMicrophone;
}

class TrtcService {
  TrtcService({AppRepository? repository})
    : _repository = repository ?? AppRepository();

  final AppRepository _repository;

  Future<TrtcCredentials> prepareJoin(TrtcJoinRequest request) {
    return _repository.fetchTrtcUserSig(
      userId: request.userId,
      roomId: request.roomId,
    );
  }

  Future<ActiveTrtcSession> joinLiveRoom({
    required LiveStreamModel stream,
    required String userId,
    bool isHost = false,
    void Function(String message)? onStatus,
  }) async {
    final String roomId = stream.roomId.isNotEmpty ? stream.roomId : stream.id;
    final TrtcCredentials credentials = await _repository.fetchTrtcUserSig(
      userId: userId,
      roomId: roomId,
    );
    onStatus?.call('TRTC UserSig hazır • SDKAppID ${credentials.sdkAppId}');

    return ActiveTrtcSession(credentials: credentials, isHost: isHost);
  }

  Future<void> leave(ActiveTrtcSession? session) async {
    return;
  }
}

class ActiveTrtcSession {
  const ActiveTrtcSession({required this.credentials, required this.isHost});

  final TrtcCredentials credentials;
  final bool isHost;
}

class TrtcIntegrationNotes {
  const TrtcIntegrationNotes._();

  static const String packageTodo =
      'Açılış crash riski nedeniyle native Tencent plugin güvenli build dışında '
      'tutuldu. UserSig ve roomId akışı hazır; cihaz logu alındıktan sonra '
      'tencent_rtc_sdk kontrollü olarak tekrar bağlanacak.';
}
