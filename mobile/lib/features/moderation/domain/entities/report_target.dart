/// Şikayet / rapor hedefi türü.
enum ReportTargetType {
  user,
  post,
  message,
  liveStream,
  voiceRoom,
  conversation,
}

/// Rapor formuna taşınan parametreler (`go_router` extra).
class ReportTarget {
  const ReportTarget({
    required this.type,
    required this.targetId,
    this.displayTitle,
    this.contextLabel,
  });

  final ReportTargetType type;
  final String targetId;
  final String? displayTitle;
  final String? contextLabel;

  String get typeLabel => switch (type) {
        ReportTargetType.user => 'Kullanıcı',
        ReportTargetType.post => 'Gönderi',
        ReportTargetType.message => 'Mesaj',
        ReportTargetType.liveStream => 'Canlı yayın',
        ReportTargetType.voiceRoom => 'Sesli oda',
        ReportTargetType.conversation => 'Sohbet',
      };

  String get apiType => switch (type) {
        ReportTargetType.user => 'user',
        ReportTargetType.post => 'post',
        ReportTargetType.message => 'message',
        ReportTargetType.liveStream => 'live_stream',
        ReportTargetType.voiceRoom => 'voice_room',
        ReportTargetType.conversation => 'conversation',
      };
}

/// Önceden tanımlı rapor nedenleri.
enum ReportReason {
  spam('spam', 'Spam veya reklam'),
  harassment('harassment', 'Taciz veya zorbalık'),
  hate('hate', 'Nefret söylemi'),
  nudity('nudity', 'Uygunsuz içerik'),
  violence('violence', 'Şiddet'),
  scam('scam', 'Dolandırıcılık'),
  impersonation('impersonation', 'Sahte hesap'),
  other('other', 'Diğer');

  const ReportReason(this.code, this.label);

  final String code;
  final String label;
}
