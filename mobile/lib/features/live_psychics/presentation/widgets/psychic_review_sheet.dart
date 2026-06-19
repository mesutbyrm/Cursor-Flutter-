import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';

/// Seans sonrası değerlendirme — `POST /api/teller/reviews`.
Future<bool?> showPsychicReviewSheet(
  BuildContext context, {
  required String sessionId,
  required String tellerId,
  required String tellerName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1028),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PsychicReviewSheet(
      sessionId: sessionId,
      tellerId: tellerId,
      tellerName: tellerName,
    ),
  );
}

class _PsychicReviewSheet extends ConsumerStatefulWidget {
  const _PsychicReviewSheet({
    required this.sessionId,
    required this.tellerId,
    required this.tellerName,
  });

  final String sessionId;
  final String tellerId;
  final String tellerName;

  @override
  ConsumerState<_PsychicReviewSheet> createState() => _PsychicReviewSheetState();
}

class _PsychicReviewSheetState extends ConsumerState<_PsychicReviewSheet> {
  var _rating = 5;
  final _commentCtrl = TextEditingController();
  var _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final ok = await ref.read(livePsychicsRepositoryProvider).submitReview(
            sessionId: widget.sessionId,
            tellerId: widget.tellerId,
            rating: _rating,
            comment: _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değerlendirmeniz kaydedildi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değerlendirme gönderilemedi')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.tellerName} ile seansınızı değerlendirin',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: _submitting ? null : () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFD54F),
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Yorumunuz (isteğe bağlı)',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.accentPurple,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Gönder',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
            child: const Text('Şimdi değil'),
          ),
        ],
      ),
    );
  }
}
