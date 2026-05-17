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
    required this.roomId,
    required this.role,
    this.enableCamera = false,
    this.enableMicrophone = false,
  });

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
      roomId: request.roomId,
      role: request.role.apiValue,
    );
  }
}

class TrtcIntegrationNotes {
  const TrtcIntegrationNotes._();

  static const String packageTodo =
      'Tencent RTC native Flutter SDK/plugin bilgisi netleşince burada gerçek '
      'enterRoom, exitRoom, camera/mic mute ve role switch çağrıları bağlanacak.';
}
