import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_colors.dart';

/// Bahşiş alındı bildirimi — Pop-up, animasyonlu, teşekkür mesajı gönderme
class PsychicTipNotificationPopup extends StatefulWidget {
  const PsychicTipNotificationPopup({
    required this.tipAmount,
    required this.senderName,
    required this.currency,
    this.onDismiss,
    this.onSendThank,
  });

  final double tipAmount;
  final String senderName;
  final String currency;
  final VoidCallback? onDismiss;
  final VoidCallback? onSendThank;

  @override
  State<PsychicTipNotificationPopup> createState() =>
      _PsychicTipNotificationPopupState();
}

class _PsychicTipNotificationPopupState
    extends State<PsychicTipNotificationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _showThankForm = false;
  final _thankController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _thankController.dispose();
    super.dispose();
  }

  void _sendThank() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Teşekkür mesajı gönderildi: "${_thankController.text}"',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    _thankController.clear();
    widget.onSendThank?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemeColors.accentCyan.withValues(alpha: 0.15),
                  AppThemeColors.accentPurple.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık & Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      size: 32,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Başlık Metni
                  const Text(
                    '🎉 Bahşiş Aldınız!',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bilgi
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        TextSpan(
                          text: widget.senderName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(
                          text: ' sana bahşiş verdi',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bahşiş Miktarı
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${widget.tipAmount.toStringAsFixed(2)} ${widget.currency}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            color: Colors.amber,
                            fontFamily: 'Courier',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bahşiş Miktarı',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Teşekkür Formu (Toggle)
                  if (!_showThankForm)
                    FilledButton.icon(
                      onPressed: () => setState(() => _showThankForm = true),
                      icon: const Icon(Icons.message_rounded, size: 16),
                      label: const Text('Teşekkür Mesajı Gönder'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppThemeColors.accentCyan,
                        minimumSize: const Size.fromHeight(42),
                      ),
                    )
                  else
                    Column(
                      children: [
                        TextField(
                          controller: _thankController,
                          decoration: InputDecoration(
                            hintText: 'Teşekkür mesajı yaz...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          maxLines: 3,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _showThankForm = false),
                                child: const Text('İptal'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: _sendThank,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppThemeColors.accentCyan,
                                ),
                                child: const Text('Gönder'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Kapat Butonu
                  OutlinedButton(
                    onPressed: () {
                      widget.onDismiss?.call();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: const Text('Kapat'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function — Bahşiş bildirimi göstermek için
Future<void> showTipNotification(
  BuildContext context, {
  required double tipAmount,
  required String senderName,
  required String currency,
  VoidCallback? onDismiss,
  VoidCallback? onSendThank,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => PsychicTipNotificationPopup(
      tipAmount: tipAmount,
      senderName: senderName,
      currency: currency,
      onDismiss: onDismiss,
      onSendThank: onSendThank,
    ),
  );
}
