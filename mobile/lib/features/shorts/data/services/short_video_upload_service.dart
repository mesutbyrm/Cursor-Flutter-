import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/short_upload_draft.dart';
import '../../domain/entities/short_video_entity.dart';
import '../datasources/shorts_remote_datasource.dart';

const int kShortVideoUploadMaxBytes = 20 * 1024 * 1024;

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
    final sourceFile = File(videoPath);
    if (await sourceFile.length() > kShortVideoUploadMaxBytes) {
      throw const ApiException('Video en fazla 20 MB olabilir.');
    }

    try {
      return await _publishViaPresigned(
        draft: draft,
        videoPath: videoPath,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
    } catch (_) {
      // Yedek yol da kullanıcının ayarlarını gönderir; önceden yalnız
      // açıklama gidiyordu → «Sadece ben» videolar herkese açık yayınlanıyordu.
      return _remote.uploadVideo(
        videoPath: videoPath,
        thumbnailPath: draft.thumbnailPath,
        description: draft.description,
        visibility: draft.visibility.wireValue,
        commentSetting: draft.commentSetting.wireValue,
        allowDuet: draft.allowDuet,
        locationName: draft.locationLabel,
        musicId: draft.musicId,
        duetOfId: draft.duetOfId,
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
    if (videoBytes.length > kShortVideoUploadMaxBytes) {
      throw const ApiException('Video en fazla 20 MB olabilir.');
    }
    final videoExt = _ext(videoPath);
    final videoMime = _videoMime(videoPath);

    onProgress?.call(0.05);

    final uploadRes = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideosUploadUrl,
      data: {
        'type': 'video',
        'contentType': videoMime,
        'extension': videoExt,
        'fileSize': videoBytes.length,
      },
      cancelToken: cancelToken,
    );

    final uploadData = _unwrapMap(uploadRes.data);
    final videoUploadUrl = uploadData['uploadUrl']?.toString() ??
        uploadData['videoUploadUrl']?.toString();
    // `register` bir URL bekler (`videoUrl`); anahtar yalnız yedek.
    final videoKey = uploadData['publicUrl']?.toString() ??
        uploadData['videoUrl']?.toString() ??
        uploadData['videoKey']?.toString() ??
        uploadData['key']?.toString();

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
      try {
        thumbKey = await uploadThumbnail(
          draft.thumbnailPath!,
          cancelToken: cancelToken,
        );
      } catch (_) {
        thumbKey = null; // kapak opsiyonel — video yine kaydedilir
      }
    }

    onProgress?.call(0.85);

    final registerRes = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideosRegister,
      data: {
        'videoUrl': videoKey,
        'videoKey': videoKey,
        if (thumbKey != null) 'thumbnailUrl': thumbKey,
        if (thumbKey != null) 'thumbnailKey': thumbKey,
        if (draft.locationLabel != null) 'locationName': draft.locationLabel,
        if (draft.locationLat != null) 'locationLat': draft.locationLat,
        if (draft.locationLng != null) 'locationLng': draft.locationLng,
        'description': draft.description.trim(),
        'visibility': draft.visibility.wireValue,
        'commentSetting': draft.commentSetting.wireValue,
        'allowDuet': draft.allowDuet,
        if (draft.musicId != null) 'musicId': draft.musicId,
        if (draft.musicTitle != null) 'musicTitle': draft.musicTitle,
        if (draft.locationLabel != null) 'location': draft.locationLabel,
        if (draft.locationLat != null) 'latitude': draft.locationLat,
        if (draft.locationLng != null) 'longitude': draft.locationLng,
        if (draft.mentionUserIds.isNotEmpty) 'mentionUserIds': draft.mentionUserIds,
        if (draft.duetOfId != null) 'duetOfId': draft.duetOfId,
        if (draft.remixOfId != null) 'remixOfId': draft.remixOfId,
        if (draft.sourceLiveClipId != null) 'liveClipId': draft.sourceLiveClipId,
        if (draft.replyToVideoId != null) 'replyToVideoId': draft.replyToVideoId,
        'contentRating': draft.contentRating.wireValue,
        if (draft.subtitlesSrt != null && draft.subtitlesSrt!.isNotEmpty)
          'subtitles': draft.subtitlesSrt,
        if (draft.aiSummary != null) 'aiSummary': draft.aiSummary,
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

  /// Kapak görselini R2'ye yükler (`upload-url` type=thumbnail) ve herkese
  /// açık URL'yi döndürür. Düzenleme ekranı da bunu kullanır.
  Future<String> uploadThumbnail(
    String imagePath, {
    CancelToken? cancelToken,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const ApiException('Kapak görseli bulunamadı.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw const ApiException('Kapak görseli en fazla 5 MB olabilir.');
    }
    final isPng = imagePath.toLowerCase().endsWith('.png');
    final mime = isPng ? 'image/png' : 'image/jpeg';
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideosUploadUrl,
      data: {'type': 'thumbnail', 'contentType': mime},
      cancelToken: cancelToken,
    );
    final data = _unwrapMap(res.data);
    final uploadUrl = data['uploadUrl']?.toString();
    final publicUrl = data['publicUrl']?.toString();
    final ct = data['contentType']?.toString() ?? mime;
    if (uploadUrl == null ||
        uploadUrl.isEmpty ||
        publicUrl == null ||
        publicUrl.isEmpty) {
      throw const ApiException('Kapak yükleme adresi alınamadı.');
    }
    await _putBytes(uploadUrl, bytes, ct, cancelToken: cancelToken);
    return publicUrl;
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
