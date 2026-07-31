import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../core/images/canlifal_network_image.dart';
import '../../data/models/platform_popup.dart';
import '../providers/platform_content_providers.dart';

/// Site geneli popup bildirimleri — `GET /api/popups`.
class AppPopupsListener extends ConsumerStatefulWidget {
  const AppPopupsListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppPopupsListener> createState() => _AppPopupsListenerState();
}

class _AppPopupsListenerState extends ConsumerState<AppPopupsListener> {
  Timer? _poll;
  final _shownIds = <String>{};
  var _dialogOpen = false;
  static const _prefsKey = 'platform_popup_seen_ids_v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(StartupPerf.shellRealtimeDelay, () {
        if (!mounted) return;
        unawaited(_loadSeen());
        unawaited(_refresh());
        _poll = Timer.periodic(const Duration(minutes: 2), (_) {
          unawaited(_refresh());
        });
      });
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _loadSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? const [];
      _shownIds.addAll(raw);
    } catch (_) {}
  }

  Future<void> _persistSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _shownIds.toList();
      if (list.length > 200) {
        list.removeRange(0, list.length - 200);
      }
      await prefs.setStringList(_prefsKey, list);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    if (!mounted || _dialogOpen) return;
    try {
      final popups = await ref.read(platformPopupsProvider.future);
      for (final popup in popups) {
        if (!mounted || _dialogOpen) return;
        if (popup.id.isEmpty) continue;
        if (!_shownIds.add(popup.id)) continue;
        await _persistSeen();
        await _showPopup(popup);
      }
    } catch (_) {}
  }

  Future<void> _showPopup(PlatformPopup popup) async {
    if (!mounted) return;
    _dialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          final image = popup.imageUrl;
          return AlertDialog(
            title: Text(popup.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (image != null && image.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CanlifalNetworkImage(
                        url: image,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (image != null && image.isNotEmpty)
                    const SizedBox(height: 12),
                  if (popup.message != null && popup.message!.trim().isNotEmpty)
                    Text(popup.message!.trim()),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kapat'),
              ),
              if (popup.actionUrl != null && popup.actionUrl!.trim().isNotEmpty)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final url = popup.actionUrl!.trim();
                    if (url.startsWith('/')) {
                      ctx.push(url);
                    }
                  },
                  child: Text(popup.actionLabel ?? 'Detay'),
                ),
            ],
          );
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
