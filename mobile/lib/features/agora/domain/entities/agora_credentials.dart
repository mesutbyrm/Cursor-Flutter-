import '../../../../core/util/json_util.dart';

/// Agora RTC — `POST /api/agora/token` yanıtı.
class AgoraCredentials {
  const AgoraCredentials({
    required this.token,
    required this.channelName,
    required this.appId,
    this.uid = 0,
  });

  /// canlifal.com üretim App ID (token yanıtında yoksa yedek).
  static const defaultAppId = 'f1cf983a38114b04a4e9102c303ba63e';

  final String token;
  final String channelName;
  final String appId;
  final int uid;

  bool matchesChannel(String channel) =>
      channelName.trim() == channel.trim() && channel.isNotEmpty;

  factory AgoraCredentials.fromJson(
    Map<String, dynamic> json, {
    String? requestedChannel,
  }) {
    final channel = pick(json, ['channelName', 'channel', 'roomId'])?.toString() ??
        requestedChannel ??
        '';
    return AgoraCredentials(
      token: pick(json, ['token', 'rtcToken'])?.toString() ?? '',
      channelName: channel,
      appId: pick(json, ['appId', 'agoraAppId'])?.toString() ?? defaultAppId,
      uid: asInt(pick(json, ['uid', 'agoraUid'])),
    );
  }

  AgoraCredentials copyWith({
    String? token,
    String? channelName,
    String? appId,
    int? uid,
  }) {
    return AgoraCredentials(
      token: token ?? this.token,
      channelName: channelName ?? this.channelName,
      appId: appId ?? this.appId,
      uid: uid ?? this.uid,
    );
  }
}
