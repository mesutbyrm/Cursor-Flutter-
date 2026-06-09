import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// googlevideo akışları Referer gerektirir — audioplayers başlık gönderemez.
/// Dio ile önbelleğe indirip yerel dosyadan oynatılır (üretimde proxy gerekmez).
class VoiceRoomDjStreamLoader {
  VoiceRoomDjStreamLoader(this._dio);

  final Dio _dio;
  final Map<String, _CacheEntry> _cache = {};

  static bool needsLocalDownload(String url) {
    final u = url.trim().toLowerCase();
    if (!u.startsWith('http')) return false;
    return u.contains('googlevideo.com') ||
        u.contains('youtube.com/api/') ||
        u.contains('/api/chat/youtube-audio');
  }

  Future<String?> preparePlaybackSource(String streamUrl) async {
    final trimmed = streamUrl.trim();
    if (trimmed.isEmpty) return null;
    if (!needsLocalDownload(trimmed)) return trimmed;

    final key = trimmed;
    final cached = _cache[key];
    if (cached != null && await File(cached.path).exists()) {
      final age = DateTime.now().difference(cached.at);
      if (age < const Duration(hours: 3)) return cached.path;
      _cache.remove(key);
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/dj_${key.hashCode.abs()}.audio',
      );
      if (await file.exists() && await file.length() > 1024) {
        _cache[key] = _CacheEntry(file.path, DateTime.now());
        return file.path;
      }

      await _dio.download(
        trimmed,
        file.path,
        options: Options(
          headers: const {
            'Referer': 'https://www.youtube.com/',
            'Origin': 'https://www.youtube.com',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
          receiveTimeout: const Duration(seconds: 50),
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
