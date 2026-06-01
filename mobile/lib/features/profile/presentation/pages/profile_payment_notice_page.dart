import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/payment_requests_notifier.dart';
import '../providers/profile_providers.dart';

/// Ödeme bildirimi — dekont ve açıklama ile yükleme talebi.
class ProfilePaymentNoticePage extends ConsumerStatefulWidget {
  const ProfilePaymentNoticePage({super.key});

  @override
  ConsumerState<ProfilePaymentNoticePage> createState() =>
      _ProfilePaymentNoticePageState();
}

class _ProfilePaymentNoticePageState
    extends ConsumerState<ProfilePaymentNoticePage> {
  final _amountCtrl = TextEditingController(text: '100');
  final _senderCtrl = TextEditingController();
  final _receiptCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  var _submitting = false;
  String _type = 'cfc';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _senderCtrl.dispose();
    _receiptCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir tutar girin')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final notes = [
        if (_receiptCtrl.text.trim().isNotEmpty)
          'Dekont: ${_receiptCtrl.text.trim()}',
        if (_notesCtrl.text.trim().isNotEmpty) _notesCtrl.text.trim(),
      ].join('\n');

      await ref.read(walletRepositoryProvider).submitPaymentRequest({
        'requestType': _type,
        'amount': amount,
        'method': 'bank_transfer',
        'senderInfo': _senderCtrl.text.trim(),
        'notes': notes,
      });
      ref.invalidate(paymentRequestsNotifierProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme bildiriminiz alındı')),
      );
      Navigator.of(context).pop();
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Ödeme Bildirimi',
          subtitle: 'Dekont linki veya referans + açıklama',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cfc', label: Text('CFC')),
                  ButtonSegment(value: 'jeton', label: Text('Jeton')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: _type == 'jeton' ? 'Jeton miktarı' : 'CFC miktarı',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senderCtrl,
                decoration: const InputDecoration(
                  labelText: 'Gönderen adı / IBAN son hanesi',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _receiptCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dekont paylaşma (link veya referans no)',
                  hintText: 'https://... veya dekont ekran görüntüsü linki',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Bildirimi gönder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
