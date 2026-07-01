import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/short_upload_draft.dart';
import '../../domain/entities/short_video_entity.dart';
import '../datasources/shorts_remote_datasource.dart';

/// R2 presigned yükleme + register; başarısız olursa doğrudan multipart fallback.
class ShortVideoUploadService {
  ShortVideoUploadService(this._dio, this._remote);

  final Dio _dio;
  final ShortsRemoteDataSource _remote;

  Future<ShortVideoEntity> publish({
    required ShortUploadDraft draft,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final videoPath = draft.videoPath;
    if (videoPath == null || videoPath.isEmpty) {
      throw const ApiException('Video dosyası bulunamadı.');
    }

    try {
      return await _publishViaPresigned(
        draft: draft,
        videoPath: videoPath,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
    } catch (_) {
      return _remote.uploadVideo(
        videoPath: videoPath,
        thumbnailPath: draft.thumbnailPath,
        description: draft.description,
      );
    }
  }

  Future<ShortVideoEntity> _publishViaPresigned({
    required ShortUploadDraft draft,
    required String videoPath,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final videoFile = File(videoPath);
    final videoBytes = await videoFile.readAsBytes();
    final videoExt = _ext(videoPath);
    final videoMime = _videoMime(videoPath);

    onProgress?.call(0.05);

    final uploadRes = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideosUploadUrl,
      data: {
        'contentType': videoMime,
        'extension': videoExt,
        'fileSize': videoBytes.length,
      },
      cancelToken: cancelToken,
    );

    final uploadData = _unwrapMap(uploadRes.data);
    final videoUploadUrl = uploadData['uploadUrl']?.toString() ??
        uploadData['videoUploadUrl']?.toString();
    final videoKey = uploadData['videoKey']?.toString() ??
        uploadData['key']?.toString() ??
        uploadData['videoUrl']?.toString();

    if (videoUploadUrl == null ||
        videoUploadUrl.isEmpty ||
        videoKey == null ||
        videoKey.isEmpty) {
      throw const ApiException('Yükleme URL alınamadı.');
    }

    onProgress?.call(0.15);

    await _putBytes(
      videoUploadUrl,
      videoBytes,
      videoMime,
      cancelToken: cancelToken,
      onProgress: (p) => onProgress?.call(0.15 + p * 0.55),
    );

    String? thumbKey;
    if (draft.thumbnailPath != null) {
      final thumbFile = File(draft.thumbnailPath!);
      if (await thumbFile.exists()) {
        final thumbBytes = await thumbFile.readAsBytes();
        final thumbRes = await _dio.safePost<dynamic>(
          ApiEndpoints.shortVideosUploadUrl,
          data: {
            'contentType': 'image/jpeg',
            'extension': 'jpg',
            'fileSize': thumbBytes.length,
            'kind': 'thumbnail',
          },
          cancelToken: cancelToken,
        );
        final thumbData = _unwrapMap(thumbRes.data);
        final thumbUrl = thumbData['uploadUrl']?.toString();
        thumbKey = thumbData['thumbnailKey']?.toString() ??
            thumbData['key']?.toString();
        if (thumbUrl != null && thumbUrl.isNotEmpty) {
          await _putBytes(
            thumbUrl,
            thumbBytes,
            'image/jpeg',
            cancelToken: cancelToken,
          );
        }
      }
    }

    onProgress?.call(0.85);

    final registerRes = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideosRegister,
      data: {
        'videoKey': videoKey,
        if (thumbKey != null) 'thumbnailKey': thumbKey,
        'description': draft.description.trim(),
        'visibility': draft.visibility.wireValue,
        'commentSetting': draft.commentSetting.wireValue,
        'allowDuet': draft.allowDuet,
        if (draft.musicId != null) 'musicId': draft.musicId,
        if (draft.locationLabel != null) 'location': draft.locationLabel,
        if (draft.locationLat != null) 'latitude': draft.locationLat,
        if (draft.locationLng != null) 'longitude': draft.locationLng,
        if (draft.mentionUserIds.isNotEmpty) 'mentionUserIds': draft.mentionUserIds,
        if (draft.duetOfId != null) 'duetOfId': draft.duetOfId,
        if (draft.remixOfId != null) 'remixOfId': draft.remixOfId,
        if (draft.sourceLiveClipId != null) 'liveClipId': draft.sourceLiveClipId,
        if (draft.textOverlays.isNotEmpty)
          'textOverlays': draft.textOverlays.map((e) => e.toJson()).toList(),
        if (draft.stickerOverlays.isNotEmpty)
          'stickers': draft.stickerOverlays.map((e) => e.toJson()).toList(),
        'playbackSpeed': draft.playbackSpeed,
        'muted': draft.muted,
      },
      cancelToken: cancelToken,
    );

    onProgress?.call(1);

    final m = _unwrapMap(registerRes.data);
    final raw = m['video'] ?? m['item'] ?? m;
    if (raw is Map) {
      return _remote.parseVideo(Map<String, dynamic>.from(raw));
    }
    throw const ApiException('Video kaydı tamamlanamadı.');
  }

  Future<void> _putBytes(
    String url,
    List<int> bytes,
    String contentType, {
    CancelToken? cancelToken,
    void Function(double progress)? onProgress,
  }) async {
    final putDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    try {
      await putDio.put<void>(
        url,
        data: bytes,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
        options: Options(headers: {'Content-Type': contentType}),
      );
    } finally {
      putDio.close(force: true);
    }
  }

  Map<String, dynamic> _unwrapMap(dynamic body) {
    if (body is! Map) return {};
    final m = Map<String, dynamic>.from(body);
    if (m['success'] == true && m['data'] is Map) {
      return Map<String, dynamic>.from(m['data'] as Map);
    }
    return m;
  }

  static String _ext(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov')) return 'mov';
    if (lower.endsWith('.webm')) return 'webm';
    return 'mp4';
  }

  static String _videoMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    return 'video/mp4';
  }
}

final shortVideoUploadServiceProvider = Provider<ShortVideoUploadService>((ref) {
  final dio = ref.watch(dioProvider);
  return ShortVideoUploadService(dio, ShortsRemoteDataSource(dio));
});
