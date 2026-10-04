import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';

/// `AsyncValue` için ortak yükleniyor / hata (yeniden dene) / boş durumu.
class ParityAsync<T> extends StatelessWidget {
  const ParityAsync({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
    this.isEmpty,
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyText = 'Henüz bir şey yok',
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final IconData emptyIcon;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ParityMessage(
        icon: Icons.cloud_off_rounded,
        text: ApiException.userMessage(e),
        actionLabel: 'Yeniden dene',
        onAction: onRetry,
      ),
      data: (d) {
        if (isEmpty != null && isEmpty!(d)) {
          return ParityMessage(icon: emptyIcon, text: emptyText);
        }
        return builder(d);
      },
    );
  }
}

/// Kaydırmayan (satır içi) yükleniyor / hata durumu.
class ParityBox<T> extends StatelessWidget {
  const ParityBox({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => const Padding(
        padding: EdgeInsets.all(18),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(ApiException.userMessage(e))),
            TextButton(onPressed: onRetry, child: const Text('Yeniden dene')),
          ],
        ),
      ),
      data: builder,
    );
  }
}

class ParityMessage extends StatelessWidget {
  const ParityMessage({
    super.key,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: c.onSurfaceMuted),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceMuted, fontSize: 14, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mor tonlu kart kabuğu.
class ParityCard extends StatelessWidget {
  const ParityCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: mockCardColor(context),
            borderRadius: r,
            border: Border.all(color: mockCardBorder(context)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class ParityChip extends StatelessWidget {
  const ParityChip(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

String parityDateLabel(DateTime? d) {
  if (d == null) return '';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
}

void parityToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
