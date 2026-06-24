/// Fal sonucunun sosyal akışa otomatik paylaşımı.
class ShareFortuneInput {
  const ShareFortuneInput({
    required this.fortuneSlug,
    required this.summary,
    this.detail,
    this.fortuneType,
    this.imageUrl,
    this.fortuneId,
    this.visualAnalysis,
    this.visibility,
  });

  final String fortuneSlug;
  final String summary;
  final String? detail;
  final String? fortuneType;
  final String? imageUrl;
  final String? fortuneId;
  final String? visualAnalysis;
  final String? visibility;
}
