import '../../domain/entities/co_broadcast_entity.dart';

class CoBroadcastDTO {
  final String id, hostId, title, description, status;
  final String? guestId;
  final DateTime startTime;
  final int viewerCount;
  final bool audioMixed, videoEnabled;
  final List<String> permissions;

  CoBroadcastDTO({required this.id, required this.hostId, this.guestId, required this.title, required this.description, required this.startTime, required this.status, required this.viewerCount, required this.audioMixed, required this.videoEnabled, required this.permissions});

  factory CoBroadcastDTO.fromJson(Map<String,dynamic> json) => CoBroadcastDTO(id: json['_id']?.toString() ?? '', hostId: json['hostId']?.toString() ?? '', guestId: json['guestId']?.toString(), title: json['title']?.toString() ?? '', description: json['description']?.toString() ?? '', startTime: json['startTime'] != null ? DateTime.parse(json['startTime'].toString()) : DateTime.now(), status: json['status']?.toString() ?? 'inactive', viewerCount: (json['viewerCount'] as num?)?.toInt() ?? 0, audioMixed: json['audioMixed'] == true, videoEnabled: json['videoEnabled'] == true, permissions: List<String>.from((json['permissions'] as List?)?.map((e) => e.toString()) ?? []));

  CoBroadcast toDomain() => CoBroadcast(id: id, hostId: hostId, guestId: guestId, title: title, description: description, startTime: startTime, status: status, viewerCount: viewerCount, audioMixed: audioMixed, videoEnabled: videoEnabled, permissions: permissions);
}

class CoBroadcastRequestDTO {
  final String id, fromUserId, toUserId, broadcastId, status;
  final DateTime createdAt;
  final String? fromUsername, toUsername;

  CoBroadcastRequestDTO({required this.id, required this.fromUserId, required this.toUserId, required this.broadcastId, required this.status, required this.createdAt, this.fromUsername, this.toUsername});

  factory CoBroadcastRequestDTO.fromJson(Map<String,dynamic> json) => CoBroadcastRequestDTO(id: json['_id']?.toString() ?? '', fromUserId: json['fromUserId']?.toString() ?? '', toUserId: json['toUserId']?.toString() ?? '', broadcastId: json['broadcastId']?.toString() ?? '', status: json['status']?.toString() ?? 'pending', createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(), fromUsername: json['fromUsername']?.toString(), toUsername: json['toUsername']?.toString());

  CoBroadcastRequest toDomain() => CoBroadcastRequest(id: id, fromUserId: fromUserId, toUserId: toUserId, broadcastId: broadcastId, status: status, createdAt: createdAt, fromUsername: fromUsername, toUsername: toUsername);
}
