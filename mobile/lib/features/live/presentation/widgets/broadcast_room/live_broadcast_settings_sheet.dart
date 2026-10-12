import 'package:canlifal_social/core/design_system/cds_bottom_sheet.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/live_guest_layout.dart';
import '../../providers/live_broadcast_settings_provider.dart';
import 'live_stream_quality_picker.dart';

/// Yayıncı — «Yayın Ayarları» bottom sheet'i (üst üste kutular).
Future<void> showLiveBroadcastSettingsSheet({
  required BuildContext context,
  required WidgetRef ref,
  TrtcRoomManager? trtc,
  String? hostName,
  String? hostAvatarUrl,
  VoidCallback? onBeautyFilter,
  VoidCallback? onShare,
  VoidCallback? onEndBroadcast,
  VoidCallback? onRtcChanged,
}) {
  return CdsBottomSheet.show<void>(
    context: context,
    child: _SettingsBody(
      trtc: trtc,
      hostName: hostName,
      hostAvatarUrl: hostAvatarUrl,
      onBeautyFilter: onBeautyFilter,
      onShare: onShare,
      onEndBroadcast: onEndBroadcast,
      onRtcChanged: onRtcChanged,
    ),
  );
}

class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody({
    this.trtc,
    this.hostName,
    this.hostAvatarUrl,
    this.onBeautyFilter,
    this.onShare,
    this.onEndBroadcast,
    this.onRtcChanged,
  });

  final TrtcRoomManager? trtc;
  final String? hostName;
  final String? hostAvatarUrl;
  final VoidCallback? onBeautyFilter;
  final VoidCallback? onShare;
  final VoidCallback? onEndBroadcast;
  final VoidCallback? onRtcChanged;

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(liveBroadcastSettingsProvider);
    final notifier = ref.read(liveBroadcastSettingsProvider.notifier);
    final trtc = widget.trtc;

    void closeThen(VoidCallback? fn) {
      if (fn == null) return;
      Navigator.pop(context);
      fn();
    }

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HostHeaderBox(
                        hostName: widget.hostName,
                        hostAvatarUrl: widget.hostAvatarUrl,
                      ),
                      const SizedBox(height: 10),
                      if (trtc != null)
                        _TwoColumnRow(
                          children: [
                            _ActionBox(
                              icon: trtc.cameraOn
                                  ? Icons.videocam_rounded
                                  : Icons.videocam_off_rounded,
                              label: 'Kamera',
                              subtitle: trtc.cameraOn ? 'Açık' : 'Kapalı',
                              onTap: () {
                                trtc.setCameraEnabled(!trtc.cameraOn);
                                widget.onRtcChanged?.call();
                                setState(() {});
                              },
                            ),
                            _ActionBox(
                              icon: trtc.micOn
                                  ? Icons.mic_rounded
                                  : Icons.mic_off_rounded,
                              label: 'Mikrofon',
                              subtitle: trtc.micOn ? 'Açık' : 'Kapalı',
                              onTap: () {
                                trtc.setMicEnabled(!trtc.micOn);
                                widget.onRtcChanged?.call();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      if (widget.onBeautyFilter != null) ...[
                        const SizedBox(height: 10),
                        _ActionBox(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Güzellik ve filtreler',
                          fullWidth: true,
                          onTap: () => closeThen(widget.onBeautyFilter),
                        ),
                      ],
                      if (widget.onShare != null) ...[
                        const SizedBox(height: 10),
                        _ActionBox(
                          icon: Icons.ios_share_rounded,
                          label: 'Paylaş',
                          fullWidth: true,
                          onTap: () => closeThen(widget.onShare),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Text(
                        'Etkileşim',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _TwoColumnRow(
                        children: [
                          _ToggleBox(
                            icon: Icons.person_add_alt_1_rounded,
                            label: 'Misafir kabul',
                            value: settings.guestsEnabled,
                            onChanged: notifier.toggleGuests,
                          ),
                          _ToggleBox(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Yorumlar',
                            value: settings.commentsEnabled,
                            onChanged: notifier.toggleComments,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _TwoColumnRow(
                        children: [
                          _ToggleBox(
                            icon: Icons.card_giftcard_rounded,
                            label: 'Hediyeler',
                            value: settings.giftsEnabled,
                            onChanged: notifier.toggleGifts,
                          ),
                          _ToggleBox(
                            icon: Icons.auto_fix_high_rounded,
                            label: 'Fal isteği',
                            value: settings.fortuneRequestsEnabled,
                            onChanged: notifier.toggleFortuneRequests,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _TwoColumnRow(
                        children: [
                          _ToggleBox(
                            icon: Icons.sports_mma_rounded,
                            label: 'PK Battle',
                            value: settings.pkEnabled,
                            onChanged: notifier.togglePk,
                          ),
                          _ToggleBox(
                            icon: Icons.grid_view_rounded,
                            label: 'Çoklu yayın',
                            value: settings.coBroadcastEnabled,
                            onChanged: notifier.toggleCoBroadcast,
                          ),
                        ],
                      ),
                      if (settings.coBroadcastEnabled) ...[
                        const SizedBox(height: 10),
                        _LayoutBox(
                          layout: settings.guestLayout,
                          onPick: notifier.setGuestLayout,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _QualityBox(),
                    ],
                  ),
                ),
              ),
              if (widget.onEndBroadcast != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => closeThen(widget.onEndBroadcast),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppThemeColors.accentPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Yayını Bitir',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HostHeaderBox extends StatelessWidget {
  const _HostHeaderBox({this.hostName, this.hostAvatarUrl});

  final String? hostName;
  final String? hostAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return _BoxShell(
      child: Row(
        children: [
          UserAvatar(url: hostAvatarUrl, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hostName?.isNotEmpty == true ? hostName! : 'Yayın Ayarları',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const Text(
                  'Yayın Ayarları',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoColumnRow extends StatelessWidget {
  const _TwoColumnRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _BoxShell extends StatelessWidget {
  const _BoxShell({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
    if (onTap == null) return inner;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: inner,
      ),
    );
  }
}

class _ActionBox extends StatelessWidget {
  const _ActionBox({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return _BoxShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: AppThemeColors.accentPink),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleBox extends StatelessWidget {
  const _ToggleBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _BoxShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: Colors.white70),
              const Spacer(),
              Switch.adaptive(
                value: value,
                activeTrackColor: AppThemeColors.accentPink.withValues(alpha: 0.45),
                activeThumbColor: AppThemeColors.accentPink,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LayoutBox extends StatelessWidget {
  const _LayoutBox({required this.layout, required this.onPick});

  final LiveGuestLayout layout;
  final ValueChanged<LiveGuestLayout> onPick;

  @override
  Widget build(BuildContext context) {
    return _BoxShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Misafir düzeni',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in LiveGuestLayout.values)
                ChoiceChip(
                  label: Text(g.label),
                  selected: layout == g,
                  onSelected: (_) => onPick(g),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QualityBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _BoxShell(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video kalitesi (düşük gecikme)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          SizedBox(height: 8),
          LiveStreamQualityPicker(compact: true, showTitle: false),
        ],
      ),
    );
  }
}
