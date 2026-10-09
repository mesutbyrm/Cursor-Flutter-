import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/agency_management_models.dart';

String fmtDate(DateTime? d, {bool time = false}) {
  if (d == null) return '—';
  final l = d.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${two(l.day)}.${two(l.month)}.${l.year}';
  return time ? '$date ${two(l.hour)}:${two(l.minute)}' : date;
}

/// Yükleniyor / hata + tekrar dene / boş durumlarını tek yerde ele alır.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
    this.isEmpty,
    this.emptyText = 'Henüz kayıt yok.',
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => InfoState(
        key: const Key('agency-mgmt-error'),
        icon: Icons.error_outline_rounded,
        text: ApiException.userMessage(e),
        actionLabel: 'Tekrar dene',
        onAction: onRetry,
      ),
      data: (d) => (isEmpty?.call(d) ?? false)
          ? InfoState(key: const Key('agency-mgmt-empty'), icon: Icons.inbox_outlined, text: emptyText, actionLabel: 'Yenile', onAction: onRetry)
          : builder(d),
    );
  }
}

class InfoState extends StatelessWidget {
  const InfoState({super.key, required this.icon, required this.text, this.actionLabel, this.onAction});
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[Icon(icon, size: 16, color: scheme.primary), const SizedBox(width: 6)],
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ],
      ),
    );
  }
}

/// İki sütunlu istatistik ızgarası.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.tiles});
  final List<StatTile> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 10) / 2;
      return Wrap(spacing: 10, runSpacing: 10, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
    });
  }
}

class UserRefTile extends StatelessWidget {
  const UserRefTile({super.key, required this.user, this.subtitle, this.trailing, this.onTap});
  final AgencyUserRef user;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: UserAvatar(url: user.image, radius: 20),
      title: Text(user.display, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Hedef ilerleme kartı (yayıncı paneli ve yayıncı ayrıntısı).
class TargetProgressCard extends StatelessWidget {
  const TargetProgressCard({super.key, required this.target, this.onClose});
  final TargetProgress target;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final t = target;
    final color = t.met ? const Color(0xFF22C55E) : Theme.of(context).colorScheme.primary;
    return Card(
      key: Key('target-${t.id}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  '${periodLabelTr(t.period)} hedef · ${formatMinutes(t.targetMinutes)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (t.met) const Icon(Icons.verified_rounded, color: Color(0xFF22C55E)),
              if (onClose != null) IconButton(tooltip: 'Hedefi kapat', onPressed: onClose, icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: t.ratio, minHeight: 10, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerçekleşen: ${formatMinutes(t.verifiedMinutes)}'
              '${t.met ? ' · Hedef tuttu' : ' · Kalan: ${formatMinutes(t.remainingMinutes)}'}',
            ),
            if (t.minDays != null) Text('Aktif gün: ${t.activeDays} / en az ${t.minDays}', style: Theme.of(context).textTheme.bodySmall),
            if (t.bonusJeton > 0) Text('Hedef bonusu: ${t.bonusJeton} Jeton', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Basit günlük çubuk grafiği (dakika).
class DailyBars extends StatelessWidget {
  const DailyBars({super.key, required this.daily});
  final List<(String, int)> daily;

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const Text('Bu aralıkta doğrulanmış yayın yok.');
    final max = daily.map((d) => d.$2).fold<int>(1, (a, b) => b > a ? b : a);
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in daily)
            Expanded(
              child: Tooltip(
                message: '${d.$1}: ${formatMinutes(d.$2)}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 90 * d.$2 / max,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 4),
                      Text(d.$1.substring(8), style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dönem seçici (Gün / Hafta / Ay).
class PeriodChips extends StatelessWidget {
  const PeriodChips({super.key, required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final p in const ['daily', 'weekly', 'monthly'])
          ChoiceChip(
            key: Key('period-$p'),
            label: Text(p == 'daily' ? 'Bugün' : p == 'weekly' ? 'Bu hafta' : 'Bu ay'),
            selected: value == p,
            onSelected: (_) => onChanged(p),
          ),
      ],
    );
  }
}

String errorText(Object e) => ApiException.userMessage(e);

/// Sunucu mesajını SnackBar ile gösterir; hata ise kırmızı.
void showResult(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: error ? Colors.red.shade700 : null),
  );
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String body, String ok = 'Onayla', Key? okKey}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(body)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
        FilledButton(key: okKey, onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
      ],
    ),
  );
  return r == true;
}

Future<String?> textInputDialog(BuildContext context, {required String title, String? hint, int maxLines = 3, Key? fieldKey}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextInputDialog(title: title, hint: hint, maxLines: maxLines, fieldKey: fieldKey),
  );
}

/// Denetleyiciyi kendi yaşam döngüsünde tutar; kapanış animasyonu sırasında
/// dispose edilmiş denetleyici kullanılmaz.
class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({required this.title, this.hint, required this.maxLines, this.fieldKey});
  final String title;
  final String? hint;
  final int maxLines;
  final Key? fieldKey;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(key: widget.fieldKey, controller: _ctrl, maxLines: widget.maxLines, decoration: InputDecoration(hintText: widget.hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: const Text('Gönder')),
      ],
    );
  }
}
