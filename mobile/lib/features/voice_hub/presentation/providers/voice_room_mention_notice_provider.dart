import 'package:flutter_riverpod/flutter_riverpod.dart';

/// «Senden bahsetti» — yalnızca etiketlenen kullanıcıya gösterilir.
class VoiceRoomMentionNotice {
  const VoiceRoomMentionNotice({
    required this.fromName,
    required this.messagePreview,
    required this.seq,
  });

  final String fromName;
  final String messagePreview;
  final int seq;
}

class VoiceRoomMentionNoticeNotifier extends Notifier<VoiceRoomMentionNotice?> {
  @override
  VoiceRoomMentionNotice? build() => null;

  void notifyMention({
    required String fromName,
    required String messagePreview,
  }) {
    state = VoiceRoomMentionNotice(
      fromName: fromName,
      messagePreview: messagePreview,
      seq: (state?.seq ?? 0) + 1,
    );
  }

  void clear() => state = null;
}

final voiceRoomMentionNoticeProvider =
    NotifierProvider<VoiceRoomMentionNoticeNotifier, VoiceRoomMentionNotice?>(
  VoiceRoomMentionNoticeNotifier.new,
);
