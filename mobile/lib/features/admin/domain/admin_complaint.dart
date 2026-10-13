import '../../../core/util/json_util.dart';

/// PR #56 backend: `pending` | `reviewed` | `dismissed` | `all`.
String complaintStatusQueryForApi(String uiStatus) {
  return switch (uiStatus) {
    'reviewing' || 'resolved' => 'reviewed',
    'pending' || 'reviewed' || 'dismissed' || 'all' => uiStatus,
    _ => 'pending',
  };
}

class AdminComplaintUser {
  const AdminComplaintUser({
    required this.id,
    this.name = '',
    this.username = '',
    this.image,
    this.role = 'user',
    this.isBanned = false,
  });

  final String id;
  final String name;
  final String username;
  final String? image;
  final String role;
  final bool isBanned;

  factory AdminComplaintUser.fromJson(Map<String, dynamic> json) {
    return AdminComplaintUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      image: json['image']?.toString(),
      role: json['role']?.toString() ?? 'user',
      isBanned: json['isBanned'] == true,
    );
  }
}

class AdminComplaint {
  const AdminComplaint({
    required this.id,
    required this.reason,
    this.details = '',
    this.status = 'pending',
    this.createdAt,
    this.reporter,
    this.reported,
  });

  final String id;
  final String reason;
  final String details;
  final String status;
  final DateTime? createdAt;
  final AdminComplaintUser? reporter;
  final AdminComplaintUser? reported;

  factory AdminComplaint.fromJson(Map<String, dynamic> json) {
    final rep = json['reporter'];
    final rpt = json['reported'];
    return AdminComplaint(
      id: json['id']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      reporter: rep is Map ? AdminComplaintUser.fromJson(asJsonMap(rep)) : null,
      reported: rpt is Map ? AdminComplaintUser.fromJson(asJsonMap(rpt)) : null,
    );
  }
}

class AdminComplaintsPageResult {
  const AdminComplaintsPageResult({
    this.reports = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.statusCounts = const {},
  });

  final List<AdminComplaint> reports;
  final int total;
  final int page;
  final int totalPages;
  final Map<String, int> statusCounts;

  factory AdminComplaintsPageResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? asJsonMap(json['data'])
        : asJsonMap(json);
    final list = data['reports'];
    final countsRaw = data['statusCounts'];
    final counts = <String, int>{};
    if (countsRaw is Map) {
      for (final e in countsRaw.entries) {
        counts[e.key.toString()] = (e.value as num?)?.toInt() ?? 0;
      }
    }
    return AdminComplaintsPageResult(
      reports: list is List
          ? list
              .whereType<Map>()
              .map((e) => AdminComplaint.fromJson(asJsonMap(e)))
              .toList()
          : const [],
      total: (data['total'] as num?)?.toInt() ?? 0,
      page: (data['page'] as num?)?.toInt() ?? 1,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      statusCounts: counts,
    );
  }
}
