import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../domain/gift_leaderboard_entry.dart';

Never _throwLast(Object error) {
  if (error is ApiException) throw error;
  throw ApiException(ApiException.userMessage(error));
}

enum GiftLeaderboardPeriod {
  session('session', 'Bu yayın'),
  weekly('weekly', 'Haftalık'),
  monthly('monthly', 'Aylık');

  const GiftLeaderboardPeriod(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class LeaderboardRemoteDataSource {
  LeaderboardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<GiftLeaderboardEntry>> fetchStreamLeaderboard(
    String streamId, {
    GiftLeaderboardPeriod period = GiftLeaderboardPeriod.session,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamGiftLeaderboard(streamId),
        query: period == GiftLeaderboardPeriod.session
            ? null
            : {'period': period.apiValue, 'range': period.apiValue},
      );
      return _parseEntries(res.data);
    } catch (_) {
      return const [];
    }
  }

  Future<List<GiftLeaderboardEntry>> fetchGlobalGiftLeaderboard({
    GiftLeaderboardPeriod period = GiftLeaderboardPeriod.weekly,
    String type = 'gifts',
  }) async {
    Object? lastError;
    var anySuccess = false;
    for (final path in [ApiEndpoints.leaderboards, ApiEndpoints.leaderboard]) {
      try {
        final res = await _dio.safeGet<dynamic>(
          path,
          query: {
            'type': type,
            'period': period.apiValue,
            'range': period.apiValue,
            'category': 'gifts',
          },
        );
        anySuccess = true;
        final list = _parseEntries(res.data);
        if (list.isNotEmpty) return list;
      } catch (e) {
        lastError = e;
      }
      try {
        final res = await _dio.safePost<dynamic>(
          path,
          data: {
            'type': type,
            'period': period.apiValue,
            'range': period.apiValue,
          },
        );
        anySuccess = true;
        final list = _parseEntries(res.data);
        if (list.isNotEmpty) return list;
      } catch (e) {
        lastError = e;
      }
    }
    if (!anySuccess && lastError != null) _throwLast(lastError);
    return const [];
  }

  List<GiftLeaderboardEntry> _parseEntries(dynamic body) {
    dynamic list;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      list = pick(data, [
        'leaders',
        'leaderboard',
        'items',
        'entries',
        'rankings',
        'gifters',
      ]);
    } else {
      list = body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => GiftLeaderboardEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.displayName.isNotEmpty && e.displayName != '—')
        .toList();
  }
}
