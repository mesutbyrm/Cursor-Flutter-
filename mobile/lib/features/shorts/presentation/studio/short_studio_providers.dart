import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/short_upload_draft_store.dart';
import '../../domain/entities/short_upload_draft.dart';

class ShortUploadDraftNotifier extends Notifier<ShortUploadDraft> {
  @override
  ShortUploadDraft build() => const ShortUploadDraft();

  void reset() => state = const ShortUploadDraft();

  void setSource(String path) =>
      state = state.copyWith(sourcePath: path, editedPath: null);

  void loadDraft(ShortUploadDraft draft) => state = draft;

  void patch(ShortUploadDraft Function(ShortUploadDraft d) fn) {
    state = fn(state);
  }

  Future<ShortSavedDraftMeta> saveDraft(String userId) async {
    return ShortUploadDraftStore.instance.save(
      userId: userId,
      draft: state,
    );
  }

  Future<void> deleteSavedDraft(String draftId) async {
    await ShortUploadDraftStore.instance.delete(draftId);
  }
}

final shortUploadDraftProvider =
    NotifierProvider<ShortUploadDraftNotifier, ShortUploadDraft>(
  ShortUploadDraftNotifier.new,
);

final shortSavedDraftsProvider =
    FutureProvider.family<List<ShortSavedDraftMeta>, String>((ref, userId) {
  if (userId.isEmpty) return Future.value(const []);
  return ShortUploadDraftStore.instance.listForUser(userId);
});

final shortUploadProgressProvider = StateProvider<double>((ref) => 0);

final shortUploadCancelTokenProvider =
    StateProvider<({bool cancelled})?>((ref) => null);
