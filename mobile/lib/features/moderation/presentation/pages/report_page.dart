import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/premium/premium.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/entities/report_target.dart';
import '../providers/moderation_providers.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key, required this.target});

  final ReportTarget target;

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  ReportReason? _reason;
  final _details = TextEditingController();
  var _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir neden seçin.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(moderationRepositoryProvider).submitReport(
            target: widget.target,
            reason: reason,
            details: _details.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Raporunuz alındı. İnceleme sürecine alındı.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gönderilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.target.displayTitle ?? widget.target.typeLabel;

    return DiscoverSubPage(
      title: 'İçeriği bildir',
      subtitle: title,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (widget.target.contextLabel != null) ...[
            Text(
              widget.target.contextLabel!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Neden bildiriyorsunuz?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in ReportReason.values)
                FilterChip(
                  label: Text(r.label),
                  selected: _reason == r,
                  onSelected: (_) => setState(() => _reason = r),
                  selectedColor: AppColors.accentPink.withValues(alpha: 0.35),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _reason == r ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: AppColors.accentPurple.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Ek açıklama (isteğe bağlı)',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _details,
            maxLines: 4,
            maxLength: 500,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Kısa açıklama yazın…',
              hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: AppColors.accentPurple.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          NeonButton(
            label: _submitting ? 'Gönderiliyor…' : 'Raporu gönder',
            icon: Icons.flag_rounded,
            onPressed: _submitting ? null : _submit,
            expand: true,
          ),
          const SizedBox(height: 12),
          Text(
            'Yanlış veya kötü niyetli raporlar hesabınızı kısıtlayabilir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
