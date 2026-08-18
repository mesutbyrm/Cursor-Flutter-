import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// googlevideo akışları Referer gerektirir.
/// Önce HTTP stream (web gibi); başarısız olursa yerel önbelleğe indirilir.
class VoiceRoomDjStreamLoader {
  VoiceRoomDjStreamLoader(this._dio);

  final Dio _dio;
  final Map<String, _CacheEntry> _cache = {};

  static const youtubeStreamHeaders = <String, String>{
    'Referer': 'https://www.youtube.com/',
    'Origin': 'https://www.youtube.com',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  };

  /// googlevideo / piped akışları için HTTP başlıkları.
  static bool needsStreamHeaders(String url) {
    final u = url.trim().toLowerCase();
    if (!u.startsWith('http')) return false;
    return needsLocalDownload(u) ||
        u.contains('pipedproxy') ||
        u.contains('kavin.rocks') ||
        u.contains('piped.video');
  }

  static bool needsLocalDownload(String url) {
    final u = url.trim().toLowerCase();
    if (!u.startsWith('http')) return false;
    if (u.contains('/api/chat/youtube-audio')) return false;
    return u.contains('googlevideo.com') || u.contains('youtube.com/api/');
  }

  /// Backend'in kendi ses proxy'si — zaten kimlik doğrulamalı, tekrar sarmaya gerek yok.
  static bool isBackendAudioProxy(String url) =>
      url.trim().toLowerCase().contains('/api/chat/youtube-audio');

  /// Web ile aynı: doğrudan stream URL (googlevideo dahil). İndirme yedek.
  Future<String?> preparePlaybackSource(String streamUrl) async {
    final trimmed = streamUrl.trim();
    if (trimmed.isEmpty) return null;
    return clientPlaybackUrl(trimmed);
  }

  /// Üretim `/api/chat/youtube-audio` yalnızca `videoId` kabul eder; `?url=` 400 döner.
  /// googlevideo CDN proxy bu yüzden kullanılmıyor — IFrame veya doğrudan CDN.
  static String? proxyPlaybackUrl(String streamUrl) => null;

  /// Android googlevideo: doğrudan CDN → yerel önbellek (kırık proxy atlanır).
  Future<List<String>> buildPlaybackTargets(String streamUrl) async {
    final trimmed = streamUrl.trim();
    if (trimmed.isEmpty) return const [];

    final targets = <String>[];
    final seen = <String>{};

    void add(String? url) {
      final u = url?.trim();
      if (u == null || u.isEmpty || !seen.add(u)) return;
      targets.add(u);
    }

    if (isBackendAudioProxy(trimmed)) {
      if (!kIsWeb && Platform.isAndroid) {
        add(await downloadFallback(trimmed));
      }
      add(trimmed);
      return targets;
    }

    final isYtCdn = needsLocalDownload(trimmed);

    if (!kIsWeb && Platform.isAndroid && isYtCdn) {
      add(trimmed);
      add(await downloadFallback(trimmed));
      return targets;
    }

    add(trimmed);
    return targets;
  }

  /// Android istemci giriş URL'si — googlevideo doğrudan (üretim proxy uyumsuz).
  static String clientPlaybackUrl(String streamUrl) {
    final trimmed = streamUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (isBackendAudioProxy(trimmed)) return trimmed;
    return trimmed;
  }

  Future<String?> downloadFallback(String streamUrl) async {
    final trimmed = streamUrl.trim();
    if (trimmed.isEmpty) return null;
    if (!needsLocalDownload(trimmed) && !isBackendAudioProxy(trimmed)) return null;

    final key = trimmed;
    final cached = _cache[key];
    if (cached != null && await File(cached.path).exists()) {
      final age = DateTime.now().difference(cached.at);
      if (age < const Duration(hours: 3)) return cached.path;
      _cache.remove(key);
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/dj_${key.hashCode.abs()}.audio');
      if (await file.exists() && await file.length() > 1024) {
        _cache[key] = _CacheEntry(file.path, DateTime.now());
        return file.path;
      }

      await _dio.download(
        trimmed,
        file.path,
        options: Options(
          headers: isBackendAudioProxy(trimmed) ? null : youtubeStreamHeaders,
          receiveTimeout: const Duration(seconds: 90),
          followRedirects: true,
        ),
      );

      if (!await file.exists() || await file.length() < 512) {
        await file.delete().catchError((_) => file);
        return null;
      }

      _cache[key] = _CacheEntry(file.path, DateTime.now());
      debugPrint('DJ stream cached: ${file.path} (${await file.length()} bytes)');
      return file.path;
    } catch (e) {
      debugPrint('DJ stream download failed: $e');
      return null;
    }
  }

  void invalidate(String streamUrl) {
    _cache.remove(streamUrl.trim());
  }
}

class _CacheEntry {
  const _CacheEntry(this.path, this.at);

  final String path;
  final DateTime at;
}
