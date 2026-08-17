import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/presentation/utils/social_caption_link_parser.dart';

void main() {
  group('parseSocialCaptionTokens', () {
    test('plain text only', () {
      final tokens = parseSocialCaptionTokens('Merhaba dünya');
      expect(tokens, hasLength(1));
      expect(tokens.first.kind, SocialCaptionTokenKind.text);
      expect(tokens.first.value, 'Merhaba dünya');
    });

    test('mention and hashtag', () {
      final tokens = parseSocialCaptionTokens('Selam @ayse #fal');
      expect(tokens, hasLength(4));
      expect(tokens[1].kind, SocialCaptionTokenKind.mention);
      expect(tokens[1].value, 'ayse');
      expect(tokens[3].kind, SocialCaptionTokenKind.hashtag);
      expect(tokens[3].value, 'fal');
    });
  });

  group('buildSocialPostShareText', () {
    test('includes caption and link', () {
      final text = buildSocialPostShareText(
        postId: 'p1',
        caption: 'Test gönderi',
      );
      expect(text, contains('Test gönderi'));
      expect(text, contains('https://canlifal.com/sosyal?post=p1'));
    });

    test('fallback without caption', () {
      final text = buildSocialPostShareText(postId: 'p2');
      expect(text, contains('Canlifal paylaşımı'));
      expect(text, contains('post=p2'));
    });
  });
}
