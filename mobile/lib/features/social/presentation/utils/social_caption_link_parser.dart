/// Sosyal gönderi metni parçası — düz metin, @etiket veya #hashtag.
enum SocialCaptionTokenKind { text, mention, hashtag }

class SocialCaptionToken {
  const SocialCaptionToken({
    required this.kind,
    required this.value,
  });

  final SocialCaptionTokenKind kind;
  final String value;
}

final socialCaptionTokenPattern = RegExp(
  r'(@[\w.]+)|(#[\w\u00C0-\u017F\u0300-\u036f]+)',
  unicode: true,
);

/// Metni @mention ve #hashtag parçalarına ayırır.
List<SocialCaptionToken> parseSocialCaptionTokens(String input) {
  if (input.isEmpty) return const [];

  final tokens = <SocialCaptionToken>[];
  var index = 0;

  for (final match in socialCaptionTokenPattern.allMatches(input)) {
    if (match.start > index) {
      tokens.add(
        SocialCaptionToken(
          kind: SocialCaptionTokenKind.text,
          value: input.substring(index, match.start),
        ),
      );
    }

    final raw = match.group(0)!;
    if (raw.startsWith('@')) {
      tokens.add(
        SocialCaptionToken(
          kind: SocialCaptionTokenKind.mention,
          value: raw.substring(1),
        ),
      );
    } else if (raw.startsWith('#')) {
      tokens.add(
        SocialCaptionToken(
          kind: SocialCaptionTokenKind.hashtag,
          value: raw.substring(1),
        ),
      );
    } else {
      tokens.add(
        SocialCaptionToken(
          kind: SocialCaptionTokenKind.text,
          value: raw,
        ),
      );
    }
    index = match.end;
  }

  if (index < input.length) {
    tokens.add(
      SocialCaptionToken(
        kind: SocialCaptionTokenKind.text,
        value: input.substring(index),
      ),
    );
  }

  return tokens;
}

/// Paylaşım metni — açıklama + canlifal.com bağlantısı.
String buildSocialPostShareText({
  required String postId,
  String? caption,
  String siteOrigin = 'https://canlifal.com',
}) {
  final base = siteOrigin.replaceAll(RegExp(r'/+$'), '');
  final link = '$base/sosyal?post=$postId';
  final trimmed = caption?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return '$trimmed\n\n$link';
  }
  return 'Canlifal paylaşımı\n$link';
}
