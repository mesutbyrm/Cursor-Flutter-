import '../models/app_models.dart';
import 'app_repository.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';

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
    required int videoViewId,
    bool isHost = false,
    void Function(String message)? onStatus,
  }) async {
    final String roomId = stream.roomId.isNotEmpty ? stream.roomId : stream.id;
    final TrtcCredentials credentials = await _repository.fetchTrtcUserSig(
      userId: userId,
      roomId: roomId,
    );
    final TRTCCloud cloud = await TRTCCloud.sharedInstance();

    late final TRTCCloudListener listener;
    listener = TRTCCloudListener(
      onEnterRoom: (int result) {
        onStatus?.call(
          result >= 0 ? 'TRTC odaya girildi' : 'TRTC giriş hatası: $result',
        );
      },
      onError: (int code, String message) {
        onStatus?.call('TRTC hata $code: $message');
      },
      onUserVideoAvailable: (String remoteUserId, bool available) {
        if (!isHost && available) {
          cloud.startRemoteView(
            remoteUserId,
            TRTCVideoStreamType.big,
            videoViewId,
          );
        }
      },
    );

    cloud.registerListener(listener);
    cloud.enterRoom(
      TRTCParams(
        sdkAppId: credentials.sdkAppId,
        userId: credentials.userId,
        userSig: credentials.userSig,
        roomId: int.tryParse(credentials.roomId) ?? 0,
        strRoomId: int.tryParse(credentials.roomId) == null
            ? credentials.roomId
            : '',
        role: isHost ? TRTCRoleType.anchor : TRTCRoleType.audience,
      ),
      TRTCAppScene.live,
    );

    if (isHost) {
      cloud.startLocalPreview(true, videoViewId);
      cloud.startLocalAudio(TRTCAudioQuality.music);
    }

    return ActiveTrtcSession(
      cloud: cloud,
      listener: listener,
      credentials: credentials,
    );
  }

  Future<void> leave(ActiveTrtcSession? session) async {
    if (session == null) {
      return;
    }

    session.cloud.unRegisterListener(session.listener);
    session.cloud.exitRoom();
  }
}

class ActiveTrtcSession {
  const ActiveTrtcSession({
    required this.cloud,
    required this.listener,
    required this.credentials,
  });

  final TRTCCloud cloud;
  final TRTCCloudListener listener;
  final TrtcCredentials credentials;
}

class TrtcIntegrationNotes {
  const TrtcIntegrationNotes._();

  static const String packageTodo =
      'Tencent RTC native Flutter SDK/plugin bilgisi netleşince burada gerçek '
      'enterRoom, exitRoom, camera/mic mute ve role switch çağrıları bağlanacak.';
}
