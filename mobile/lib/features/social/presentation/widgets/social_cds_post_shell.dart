import 'package:flutter/material.dart';

/// Sosyal akış kartı aralığı — kart yüzeyini [SocialInstagramPostCard] çizer.
class SocialCdsPostShell extends StatelessWidget {
  const SocialCdsPostShell({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 4),
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Padding(padding: margin, child: child);
}
