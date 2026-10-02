import 'package:canlifal_social/core/design_system/cds_bottom_sheet.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/live_guest_layout.dart';
import '../../providers/live_broadcast_settings_provider.dart';
import 'live_stream_quality_picker.dart';

/// Yayıncı — «Yayın Ayarları» bottom sheet'i.
///
/// Üst: yayıncı kartı · hızlı eylemler (kamera, mikrofon, güzellik/filtre,
/// paylaş) · etkileşim anahtarları · «Yayını Bitir».
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
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: UserAvatar(
                          url: widget.hostAvatarUrl,
                          radius: 22,
                        ),
                        title: Text(
                          widget.hostName?.isNotEmpty == true
                              ? widget.hostName!
                              : 'Yayın Ayarları',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: const Text('Yayın Ayarları'),
                      ),
                      if (trtc != null) ...[
                        _ActionRow(
                          icon: trtc.cameraOn
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          label: 'Kamera Aç/Kapat',
                          value: trtc.cameraOn ? 'Açık' : 'Kapalı',
                          onTap: () {
                            trtc.setCameraEnabled(!trtc.cameraOn);
                            widget.onRtcChanged?.call();
                            setState(() {});
                          },
                        ),
                        _ActionRow(
                          icon: trtc.micOn
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          label: 'Mikrofon Aç/Kapat',
                          value: trtc.micOn ? 'Açık' : 'Kapalı',
                          onTap: () {
                            trtc.setMicEnabled(!trtc.micOn);
                            widget.onRtcChanged?.call();
                            setState(() {});
                          },
                        ),
                      ],
                      if (widget.onBeautyFilter != null)
                        _ActionRow(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Güzellik Efektleri ve Filtreler',
                          onTap: () => closeThen(widget.onBeautyFilter),
                        ),
                      if (widget.onShare != null)
                        _ActionRow(
                          icon: Icons.ios_share_rounded,
                          label: 'Paylaş',
                          onTap: () => closeThen(widget.onShare),
                        ),
                      const Divider(height: 20),
                      _SwitchRow(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Misafir Kabul Et',
                        value: settings.guestsEnabled,
                        onChanged: notifier.toggleGuests,
                      ),
                      _SwitchRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Yorumlar',
                        value: settings.commentsEnabled,
                        onChanged: notifier.toggleComments,
                      ),
                      _SwitchRow(
                        icon: Icons.card_giftcard_rounded,
                        label: 'Hediyeler',
                        value: settings.giftsEnabled,
                        onChanged: notifier.toggleGifts,
                      ),
                      _SwitchRow(
                        icon: Icons.auto_fix_high_rounded,
                        label: 'Fal isteği kabul et',
                        value: settings.fortuneRequestsEnabled,
                        onChanged: notifier.toggleFortuneRequests,
                      ),
                      _SwitchRow(
                        icon: Icons.sports_mma_rounded,
                        label: 'PK Battle',
                        value: settings.pkEnabled,
                        onChanged: notifier.togglePk,
                      ),
                      _SwitchRow(
                        icon: Icons.grid_view_rounded,
                        label: 'Çoklu yayın',
                        value: settings.coBroadcastEnabled,
                        onChanged: notifier.toggleCoBroadcast,
                      ),
                      if (settings.coBroadcastEnabled)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final g in LiveGuestLayout.values)
                                ChoiceChip(
                                  label: Text(g.label),
                                  selected: settings.guestLayout == g,
                                  onSelected: (_) => notifier.setGuestLayout(g),
                                ),
                            ],
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Video kalitesi (düşük gecikme)',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const LiveStreamQualityPicker(
                        compact: true,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              // Sabit alt: kaydırma uzunluğundan bağımsız her zaman erişilebilir.
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: value != null
          ? Text(value!, style: const TextStyle(color: Colors.white60))
          : const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: onTap,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
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
    return SwitchListTile(
      dense: true,
      secondary: Icon(icon, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      value: value,
      activeThumbColor: AppThemeColors.accentPink,
      onChanged: onChanged,
    );
  }
}
