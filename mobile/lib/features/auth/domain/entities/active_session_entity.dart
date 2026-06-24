import 'package:equatable/equatable.dart';

class ActiveSessionEntity extends Equatable {
  const ActiveSessionEntity({
    required this.id,
    required this.deviceLabel,
    required this.devicePlatform,
    required this.lastSeenAt,
    required this.createdAt,
    required this.expiresAt,
    this.current = false,
  });

  final String id;
  final String deviceLabel;
  final String devicePlatform;
  final DateTime lastSeenAt;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool current;

  factory ActiveSessionEntity.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    // API'den şifre alanı gelirse asla kullanılmaz / gösterilmez.
    final label = json['deviceLabel']?.toString() ??
        json['deviceName']?.toString() ??
        'Bilinmeyen cihaz';

    return ActiveSessionEntity(
      id: json['id']?.toString() ?? '',
      deviceLabel: label,
      devicePlatform: json['devicePlatform']?.toString() ?? 'unknown',
      lastSeenAt: parseDate(json['lastSeenAt']),
      createdAt: parseDate(json['createdAt']),
      expiresAt: parseDate(json['expiresAt']),
      current: json['current'] == true,
    );
  }

  @override
  List<Object?> get props => [id, deviceLabel, devicePlatform, lastSeenAt];
}
