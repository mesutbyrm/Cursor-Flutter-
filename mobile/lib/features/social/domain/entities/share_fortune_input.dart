/// Fal sonucunun sosyal akışa otomatik paylaşımı.
class ShareFortuneInput {
  const ShareFortuneInput({
    required this.fortuneSlug,
    required this.summary,
    this.detail,
    this.fortuneType,
  });

  final String fortuneSlug;
  final String summary;
  final String? detail;
  final String? fortuneType;
}
