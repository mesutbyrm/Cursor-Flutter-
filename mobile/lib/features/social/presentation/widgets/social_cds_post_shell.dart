import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/cds.dart';

/// Sosyal akış kartı — CDS cam yüzey sarmalayıcı.
class SocialCdsPostShell extends ConsumerWidget {
  const SocialCdsPostShell({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 14),
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: margin,
      child: CdsCard(
        variant: CdsCardVariant.glass,
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
