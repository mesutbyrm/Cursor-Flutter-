import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../platform/data/models/platform_popup.dart';
import '../../../platform/presentation/providers/platform_content_providers.dart';
import '../../../voice_hub/presentation/theme/voice_room_tokens.dart';

class VoiceRoomCampaignState {
  const VoiceRoomCampaignState({this.active});

  final PlatformPopup? active;
}

/// Sesli oda sağ üst kampanya kutusu — `GET /api/popups`.
class VoiceRoomCampaignController extends Notifier<VoiceRoomCampaignState> {
  static const _prefsPrefix = 'voice_campaign_seen_';
  Timer? _poll;

  @override
  VoiceRoomCampaignState build() {
    ref.onDispose(() => _poll?.cancel());
    Future.microtask(_refresh);
    _poll = Timer.periodic(const Duration(minutes: 2), (_) => _refresh());
    return const VoiceRoomCampaignState();
  }

  Future<void> _refresh() async {
    try {
      final popups = await ref.read(platformPopupsProvider.future);
      for (final popup in popups) {
        if (popup.id.isEmpty) continue;
        final type = popup.type?.toLowerCase() ?? '';
        if (!_isVoiceRoomCampaign(popup, type)) continue;
        final seen = await _wasSeen(popup.id);
        if (seen) continue;
        state = VoiceRoomCampaignState(active: popup);
        return;
      }
    } catch (_) {}
  }

  bool _isVoiceRoomCampaign(PlatformPopup popup, String type) {
    if (type.contains('voice') ||
        type.contains('room') ||
        type.contains('campaign') ||
        type.contains('jeton') ||
        type.contains('membership')) {
      return true;
    }
    final title = popup.title.toLowerCase();
    return title.contains('jeton') ||
        title.contains('indirim') ||
        title.contains('kampanya') ||
        title.contains('üyelik');
  }

  Future<bool> _wasSeen(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_prefsPrefix$id') == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> dismiss() async {
    final popup = state.active;
    if (popup != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('$_prefsPrefix${popup.id}', true);
      } catch (_) {}
    }
    state = const VoiceRoomCampaignState();
  }

  Future<void> onTap(BuildContext context) async {
    final popup = state.active;
    if (popup == null) return;
    final url = popup.actionUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      if (url.startsWith('/')) {
        if (context.mounted) context.push(url);
      } else if (url.startsWith('canlifal://') || url.contains('canlifal.com')) {
        final path = Uri.tryParse(url)?.path;
        if (path != null && path.isNotEmpty && context.mounted) {
          context.push(path);
        }
      }
    }
    await dismiss();
  }
}

final voiceRoomCampaignProvider =
    NotifierProvider<VoiceRoomCampaignController, VoiceRoomCampaignState>(
  VoiceRoomCampaignController.new,
);

/// Sağ üst kampanya kutusu.
class FxVoiceRoomCampaignBox extends ConsumerWidget {
  const FxVoiceRoomCampaignBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popup = ref.watch(voiceRoomCampaignProvider.select((s) => s.active));
    if (popup == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        right: 8,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(voiceRoomCampaignProvider.notifier).onTap(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VoiceRoomTokens.gold.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: VoiceRoomTokens.gold.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: VoiceRoomTokens.gold.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        popup.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          ref.read(voiceRoomCampaignProvider.notifier).dismiss(),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                if (popup.message?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    popup.message!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.2,
                    ),
                  ),
                ],
                if (popup.actionLabel?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    popup.actionLabel!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: VoiceRoomTokens.gold.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
