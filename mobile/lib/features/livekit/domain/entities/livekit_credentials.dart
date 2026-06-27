import 'package:equatable/equatable.dart';

class LiveKitCredentials extends Equatable {
  const LiveKitCredentials({
    required this.token,
    required this.url,
    required this.roomName,
    required this.identity,
  });

  factory LiveKitCredentials.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return LiveKitCredentials(
      token: data['token']?.toString() ?? '',
      url: data['url']?.toString() ?? '',
      roomName: data['roomName']?.toString() ?? data['room']?.toString() ?? '',
      identity: data['identity']?.toString() ?? '',
    );
  }

  final String token;
  final String url;
  final String roomName;
  final String identity;

  bool get isValid => token.isNotEmpty && url.isNotEmpty && roomName.isNotEmpty;

  @override
  List<Object?> get props => [token, url, roomName, identity];
}
