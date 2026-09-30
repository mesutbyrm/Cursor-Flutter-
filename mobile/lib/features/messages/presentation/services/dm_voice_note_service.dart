import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/media/cloud_upload_service.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/utils/dm_message_codec.dart';
import '../providers/messages_providers.dart';

final dmVoiceNoteRecorderProvider = Provider<AudioRecorder>((ref) {
  final recorder = AudioRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

final dmVoiceNoteUploadProvider = Provider<CloudMediaUploadService>((ref) {
  return CloudMediaUploadService(ref.read(dioProvider));
});

/// DM sesli mesaj — kayıt, yükleme, 24 saat sonra istemci tarafında gizlenir.
class DmVoiceNoteService {
  DmVoiceNoteService(this._ref);

  final Ref _ref;

  Future<String?> recordAndUpload({
    required void Function(bool recording) onRecordingChanged,
  }) async {
    final recorder = _ref.read(dmVoiceNoteRecorderProvider);
    if (await recorder.isRecording()) {
      onRecordingChanged(false);
      final path = await recorder.stop();
      if (path == null || path.isEmpty) return null;
      final file = File(path);
      if (!await file.exists()) return null;
      final upload = _ref.read(dmVoiceNoteUploadProvider);
      final url = await upload.uploadImageFile(
        file,
        folder: 'dm-voice-notes',
        isPublic: true,
        requireSiteOrigin: true,
      );
      try {
        await file.delete();
      } catch (_) {}
      return url;
    }
    if (!await recorder.hasPermission()) return null;
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/dm_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await recorder.start(const RecordConfig(), path: filePath);
    onRecordingChanged(true);
    return null;
  }

  Future<void> sendVoiceNote({
    required String peerUserId,
    required String audioUrl,
  }) async {
    final expiresAt =
        DateTime.now().toUtc().add(const Duration(hours: 24));
    final payload = DmMessageCodec.wrapVoiceNote(
      url: audioUrl,
      expiresAt: expiresAt,
    );
    await _ref.read(messagesRepositoryProvider).sendMessage(
          peerUserId,
          payload,
        );
  }
}

final dmVoiceNoteServiceProvider = Provider<DmVoiceNoteService>((ref) {
  return DmVoiceNoteService(ref);
});
