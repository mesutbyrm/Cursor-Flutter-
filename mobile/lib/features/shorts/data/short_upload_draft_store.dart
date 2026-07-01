import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/short_upload_draft.dart';

/// Video stüdyosu taslaklarını kalıcı olarak saklar.
class ShortUploadDraftStore {
  ShortUploadDraftStore._();

  static final ShortUploadDraftStore instance = ShortUploadDraftStore._();

  static const _indexKey = 'short_studio_draft_index_v1';

  Future<List<ShortSavedDraftMeta>> listForUser(String userId) async {
    if (userId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_indexKey) ?? const [];
    final out = <ShortSavedDraftMeta>[];
    for (final line in raw) {
      try {
        final map = jsonDecode(line) as Map<String, dynamic>;
        final meta = ShortSavedDraftMeta.fromJson(map);
        if (meta.userId == userId) out.add(meta);
      } catch (_) {}
    }
    out.sort((a, b) => b.savedAtMs.compareTo(a.savedAtMs));
    return out;
  }

  Future<ShortUploadDraft?> load(String draftId) async {
    final dir = await _draftDir(draftId);
    final file = File('${dir.path}/draft.json');
    if (!await file.exists()) return null;
    try {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final draft = ShortUploadDraft.fromJson(map);
      if (draft.videoPath == null) return null;
      final video = File(draft.videoPath!);
      if (!await video.exists()) return null;
      return draft;
    } catch (_) {
      return null;
    }
  }

  Future<ShortSavedDraftMeta> save({
    required String userId,
    required ShortUploadDraft draft,
    String? draftId,
  }) async {
    final id = draftId ?? const Uuid().v4();
    final dir = await _draftDir(id);
    final persisted = await _persistFiles(dir, draft);
    final meta = ShortSavedDraftMeta(
      id: id,
      userId: userId,
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
      previewLabel: _previewLabel(persisted),
      thumbnailPath: persisted.thumbnailPath,
    );
    await File('${dir.path}/draft.json').writeAsString(
      jsonEncode(persisted.toJson()),
    );
    await _upsertMeta(meta);
    return meta;
  }

  Future<void> delete(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_indexKey) ?? const [];
    final kept = raw.where((line) {
      try {
        final map = jsonDecode(line) as Map<String, dynamic>;
        return map['id']?.toString() != draftId;
      } catch (_) {
        return true;
      }
    }).toList();
    await prefs.setStringList(_indexKey, kept);
    final dir = await _draftDir(draftId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<Directory> _draftDir(String draftId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/short_drafts/$draftId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<ShortUploadDraft> _persistFiles(
    Directory dir,
    ShortUploadDraft draft,
  ) async {
    Future<String?> copy(String? path, String name) async {
      if (path == null || path.isEmpty) return null;
      final src = File(path);
      if (!await src.exists()) return null;
      final dest = '${dir.path}/$name';
      await src.copy(dest);
      return dest;
    }

    final source = await copy(draft.sourcePath, 'source.mp4');
    final edited = await copy(draft.editedPath, 'edited.mp4');
    final thumb = await copy(draft.thumbnailPath, 'thumb.jpg');
    final voice = await copy(draft.voiceoverPath, 'voice.m4a');

    return draft.copyWith(
      sourcePath: source ?? draft.sourcePath,
      editedPath: edited ?? draft.editedPath,
      thumbnailPath: thumb ?? draft.thumbnailPath,
      voiceoverPath: voice ?? draft.voiceoverPath,
    );
  }

  String _previewLabel(ShortUploadDraft draft) {
    final desc = draft.description.trim();
    if (desc.isNotEmpty) {
      return desc.length > 48 ? '${desc.substring(0, 48)}…' : desc;
    }
    if (draft.musicTitle != null && draft.musicTitle!.isNotEmpty) {
      return draft.musicTitle!;
    }
    return 'Video taslağı';
  }

  Future<void> _upsertMeta(ShortSavedDraftMeta meta) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_indexKey) ?? const [];
    final encoded = jsonEncode(meta.toJson());
    final next = [
      for (final line in raw)
        if (_idFromLine(line) != meta.id) line,
      encoded,
    ];
    await prefs.setStringList(_indexKey, next);
  }

  String? _idFromLine(String line) {
    try {
      final map = jsonDecode(line) as Map<String, dynamic>;
      return map['id']?.toString();
    } catch (_) {
      return null;
    }
  }
}
