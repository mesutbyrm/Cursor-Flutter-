import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/short_upload_draft.dart';

class ShortUploadDraftNotifier extends Notifier<ShortUploadDraft> {
  @override
  ShortUploadDraft build() => const ShortUploadDraft();

  void reset() => state = const ShortUploadDraft();

  void setSource(String path) =>
      state = state.copyWith(sourcePath: path, editedPath: null);

  void patch(ShortUploadDraft Function(ShortUploadDraft d) fn) {
    state = fn(state);
  }
}

final shortUploadDraftProvider =
    NotifierProvider<ShortUploadDraftNotifier, ShortUploadDraft>(
  ShortUploadDraftNotifier.new,
);

final shortUploadProgressProvider = StateProvider<double>((ref) => 0);

final shortUploadCancelTokenProvider =
    StateProvider<({bool cancelled})?>((ref) => null);
