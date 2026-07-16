import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/system/presentation/force_update_screen.dart';
import '../../features/system/presentation/maintenance_screen.dart';
import 'mobile_config_providers.dart';

/// Mobil config sonucuna göre bakım / güncelleme kontrolü.
class MobileConfigGate extends ConsumerStatefulWidget {
  const MobileConfigGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MobileConfigGate> createState() => _MobileConfigGateState();
}

class _MobileConfigGateState extends ConsumerState<MobileConfigGate> {
  var _optionalUpdateShown = false;

  Future<void> _showOptionalUpdate({
    required String message,
    String? storeUrl,
  }) async {
    if (!mounted || _optionalUpdateShown) return;
    _optionalUpdateShown = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni sürüm mevcut'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sonra'),
          ),
          if (storeUrl != null && storeUrl.trim().isNotEmpty)
            FilledButton(
              onPressed: () async {
                final uri = Uri.tryParse(storeUrl.trim());
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Güncelle'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(mobileConfigProvider);

    ref.listen(mobileConfigProvider, (prev, next) {
      final config = next.valueOrNull;
      if (config == null) return;
      if (config.maintenance.enabled || config.version.forceUpdate) return;
      if (!config.version.optionalUpdate || _optionalUpdateShown) return;
      final message = config.version.optionalUpdateMessage?.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          _showOptionalUpdate(
            message: message?.isNotEmpty == true
                ? message!
                : 'Yeni bir sürüm yayınlandı. Güncellemek ister misiniz?',
            storeUrl: config.version.storeUrl,
          ),
        );
      });
    });

    final config = configAsync.valueOrNull;
    if (config != null) {
      if (config.maintenance.enabled) {
        return MaintenanceScreen(message: config.maintenance.message);
      }
      if (config.version.forceUpdate) {
        return ForceUpdateScreen(
          message: config.version.forceUpdateMessage,
          storeUrl: config.version.storeUrl,
        );
      }
    }

    return widget.child;
  }
}
