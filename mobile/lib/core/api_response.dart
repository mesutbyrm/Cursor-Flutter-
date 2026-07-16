import 'package:dio/dio.dart';

/// Tek alan doğrulama hatası — `error.details[]`.
class FieldError {
  const FieldError({
    required this.field,
    required this.message,
  });

  final String field;
  final String message;

  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      field: (json['field'] ?? json['path'] ?? json['param'] ?? '')
          .toString(),
      message: (json['message'] ?? json['error'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field,
        'message': message,
      };
}

/// Yapılandırılmış API hatası.
class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final List<FieldError>? details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'] ?? json['errors'] ?? json['fields'];
    List<FieldError>? details;
    if (rawDetails is List) {
      details = rawDetails
          .whereType<Map>()
          .map((e) => FieldError.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      if (details.isEmpty) details = null;
    }
    return ApiError(
      code: (json['code'] ?? json['type'] ?? 'UNKNOWN').toString(),
      message: (json['message'] ??
              json['detail'] ??
              json['title'] ??
              json['description'] ??
              '')
          .toString(),
      details: details,
    );
  }

  factory ApiError.legacy(String message, {String code = 'UNKNOWN'}) {
    return ApiError(code: code, message: message);
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (details != null)
          'details': details!.map((d) => d.toJson()).toList(growable: false),
      };
}

/// Sayfalama meta verisi — `?page=1&limit=20` liste uçları.
class Pagination {
  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    final page = _asInt(json['page'], fallback: 1);
    final limit = _asInt(json['limit'], fallback: 20);
    final total = _asInt(json['total'] ?? json['totalCount'] ?? json['count']);
    final totalPages = _asInt(
      json['totalPages'] ?? json['total_pages'] ?? json['pageCount'],
      fallback: limit > 0 ? ((total + limit - 1) / limit).ceil() : 0,
    );
    final hasNext = json['hasNext'] == true ||
        json['hasMore'] == true ||
        (json['hasNext'] == null && page < totalPages);
    final hasPrev =
        json['hasPrev'] == true || (json['hasPrev'] == null && page > 1);

    return Pagination(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrev: hasPrev,
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': totalPages,
        'hasNext': hasNext,
        'hasPrev': hasPrev,
      };

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}

/// Standart API zarfı — yeni `{ success, data, error }` ve eski düz JSON.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.pagination,
    this.requestId,
  });

  final bool success;
  final T? data;
  final ApiError? error;
  final Pagination? pagination;
  final String? requestId;

  bool get isOk => success && error == null;

  ApiResponse<R> map<R>(R Function(T value) transform) {
    final value = data;
    if (!success || value == null) {
      return ApiResponse<R>(
        success: false,
        error: error,
        pagination: pagination,
        requestId: requestId,
      );
    }
    return ApiResponse<R>(
      success: true,
      data: transform(value),
      pagination: pagination,
      requestId: requestId,
    );
  }

  T get requireData {
    if (!success || data == null) {
      throw StateError(error?.message ?? 'API yanıtında data yok');
    }
    return data as T;
  }
}

/// Liste uçları için `?page=&limit=` sorgu parametreleri.
Map<String, dynamic> apiPageQuery({
  int page = 1,
  int limit = 20,
}) =>
    {
      'page': page,
      'limit': limit,
    };

/// Dio yanıtını [ApiResponse] olarak ayrıştırır (geriye dönük uyumlu).
///
/// 1. `{ success: true, data: ... }` — yeni format
/// 2. `{ success: false, error: { code, message } }` — yapılandırılmış hata
/// 3. `{ error: "mesaj" }` — eski string hata
/// 4. Düz JSON — eski format (doğrudan `data` gövdesi)
ApiResponse<T> parseResponse<T>(
  Response<dynamic> response,
  T Function(dynamic json) fromJson,
) {
  final json = response.data;
  final requestId = _requestIdFrom(response);

  if (json is! Map) {
    if (json == null) {
      return ApiResponse<T>(
        success: false,
        error: const ApiError(code: 'EMPTY_BODY', message: 'Boş yanıt'),
        requestId: requestId,
      );
    }
    return ApiResponse<T>(
      success: true,
      data: fromJson(json),
      requestId: requestId,
    );
  }

  final map = Map<String, dynamic>.from(json);

  if (map['success'] == true) {
    return ApiResponse<T>(
      success: true,
      data: fromJson(map['data']),
      pagination: _paginationFrom(map),
      requestId: requestId ?? map['requestId']?.toString(),
    );
  }

  if (map['success'] == false) {
    return ApiResponse<T>(
      success: false,
      error: _errorFrom(map),
      pagination: _paginationFrom(map),
      requestId: requestId ?? map['requestId']?.toString(),
    );
  }

  final nestedError = map['error'];
  if (nestedError is Map) {
    return ApiResponse<T>(
      success: false,
      error: ApiError.fromJson(Map<String, dynamic>.from(nestedError)),
      pagination: _paginationFrom(map),
      requestId: requestId ?? map['requestId']?.toString(),
    );
  }

  if (nestedError is String && nestedError.trim().isNotEmpty) {
    return ApiResponse<T>(
      success: false,
      error: ApiError.legacy(nestedError.trim()),
      pagination: _paginationFrom(map),
      requestId: requestId,
    );
  }

  // Eski format: gövde doğrudan veri (liste veya nesne).
  return ApiResponse<T>(
    success: true,
    data: fromJson(map),
    pagination: _paginationFrom(map),
    requestId: requestId,
  );
}

ApiError _errorFrom(Map<String, dynamic> map) {
  final nested = map['error'];
  if (nested is Map) {
    return ApiError.fromJson(Map<String, dynamic>.from(nested));
  }
  if (nested is String && nested.trim().isNotEmpty) {
    return ApiError.legacy(nested.trim());
  }
  final message = map['message']?.toString();
  if (message != null && message.isNotEmpty) {
    return ApiError.legacy(message);
  }
  return const ApiError(code: 'UNKNOWN', message: 'İşlem başarısız');
}

Pagination? _paginationFrom(Map<String, dynamic> map) {
  final raw = map['pagination'] ?? map['meta'] ?? map['pageInfo'];
  if (raw is Map) {
    return Pagination.fromJson(Map<String, dynamic>.from(raw));
  }
  if (map.containsKey('page') ||
      map.containsKey('limit') ||
      map.containsKey('total')) {
    return Pagination.fromJson(map);
  }
  return null;
}

String? _requestIdFrom(Response<dynamic> response) {
  final header = response.headers.value('x-request-id') ??
      response.headers.value('X-Request-Id');
  if (header != null && header.isNotEmpty) return header;
  final data = response.data;
  if (data is Map) {
    return data['requestId']?.toString() ?? data['request_id']?.toString();
  }
  return null;
}
