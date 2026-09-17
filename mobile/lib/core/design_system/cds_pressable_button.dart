import 'package:flutter/material.dart';

import '../motion/canlifal_motion_widgets.dart';

/// CDS buton sarmalayıcı — press scale (Material onPressed korunur).
class CdsPressableButton extends StatelessWidget {
  const CdsPressableButton({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return CanlifalPressable(
      onTap: enabled ? onPressed : null,
      enabled: enabled && onPressed != null,
      child: child,
    );
  }
}
