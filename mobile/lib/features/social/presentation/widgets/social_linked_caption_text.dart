import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/social_caption_link_parser.dart';

/// Gönderi metninde @mention ve #hashtag bağlantıları.
class SocialLinkedCaptionText extends StatefulWidget {
  const SocialLinkedCaptionText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;

  @override
  State<SocialLinkedCaptionText> createState() => _SocialLinkedCaptionTextState();
}

class _SocialLinkedCaptionTextState extends State<SocialLinkedCaptionText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  void _openToken(SocialCaptionToken token) {
    switch (token.kind) {
      case SocialCaptionTokenKind.hashtag:
        context.push(
          '/shorts/hashtag/${Uri.encodeComponent(token.value)}',
        );
      case SocialCaptionTokenKind.mention:
        context.push(
          Uri(
            path: '/search',
            queryParameters: {'q': '@${token.value}'},
          ).toString(),
        );
      case SocialCaptionTokenKind.text:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final linkStyle = widget.linkStyle ??
        baseStyle.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        );

    final spans = <InlineSpan>[];
    for (final token in parseSocialCaptionTokens(widget.text)) {
      switch (token.kind) {
        case SocialCaptionTokenKind.text:
          spans.add(TextSpan(text: token.value, style: baseStyle));
        case SocialCaptionTokenKind.mention:
        case SocialCaptionTokenKind.hashtag:
          final recognizer = TapGestureRecognizer()
            ..onTap = () => _openToken(token);
          _recognizers.add(recognizer);
          final prefix = token.kind == SocialCaptionTokenKind.mention ? '@' : '#';
          spans.add(
            TextSpan(
              text: '$prefix${token.value}',
              style: linkStyle,
              recognizer: recognizer,
            ),
          );
      }
    }

    return Text.rich(TextSpan(children: spans));
  }
}
