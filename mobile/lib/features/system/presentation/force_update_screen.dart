import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Zorunlu güncelleme — `version.forceUpdate == true`.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({
    super.key,
    this.message,
    this.storeUrl,
  });

  final String? message;
  final String? storeUrl;

  Future<void> _openStore() async {
    final url = storeUrl?.trim();
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final text = (message?.trim().isNotEmpty == true)
        ? message!.trim()
        : 'Devam etmek için uygulamayı güncellemeniz gerekiyor.';

    return Material(
      color: const Color(0xFF05050D),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                size: 56,
                color: Color(0xFF9B4DFF),
              ),
              const SizedBox(height: 20),
              const Text(
                'Güncelleme gerekli',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              if (storeUrl != null && storeUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _openStore,
                  child: const Text('Mağazaya git'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
