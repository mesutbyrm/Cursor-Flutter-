import 'package:canlifal_social/core/design_system/cds_bottom_sheet.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../pk/presentation/providers/pk_feature_enabled_provider.dart';
import '../../../pk/presentation/widgets/pk_start_sheet.dart';
import 'voice_in_room_pk_sheet.dart';
import '../../../gifts/presentation/providers/gift_battle_providers.dart';
import '../../../gifts/presentation/providers/gift_goal_providers.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_ban_entry.dart';
import '../../domain/entities/voice_room_violation.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../../../vip_gold/domain/voice_room_access.dart';
import '../../domain/voice_room_background_policy.dart';
import '../providers/chat_room_providers.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_room_ui_provider.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_room_permissions.dart';
import '../utils/voice_room_user_actions.dart';
import '../utils/voice_room_category_catalog.dart';
import '../utils/voice_room_seat_capacity.dart';
import 'voice_room_music_settings_sheet.dart';
import '../widgets/premium/voice_glass.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import '../widgets/premium/voice_mgmt_card.dart';
import 'voice_room_commands_panel.dart';
import 'voice_room_hub_settings.dart';
import 'voice_room_menu_sheet.dart' show VoiceRoomMenuRole;
import 'voice_room_moderation_sheet.dart';
import 'voice_room_muted_users_sheet.dart';
import 'voice_room_sheets.dart';
import 'voice_room_voice_users_sheet.dart';
import 'voice_youtube_song_sheet.dart';
import 'voice_room_speak_queue_sheet.dart';
import 'voice_room_tools_sheet.dart';
import '../widgets/voice_room/voice_gift_goal_start_modal.dart';

enum VoiceMgmtInitial { home, userMgmt, users, chatMgmt, roomMgmt, userSettings }

enum _MgmtView {
  home,
  userMgmt,
  chatMgmt,
  roomMgmt,
  userSettings,
  users,
  penalties,
  chatSettings,
  roomInfo,
  vipSecurity,
  authority,
  seats,
  access,
  roomTools,
  userSound,
  userMic,
  userNotifications,
  userAppearance,
  userOther,
  autoMod,
}

enum _PenaltyTab { muted, banned, temporary, warnings }

/// Oda ayarları — Kullanıcı / Sohbet / Oda yönetimi / Kullanıcı ayarları.
Future<void> showVoiceRoomManagementPanel(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required bool isOwner,
  void Function(ChatRoomPresence user)? onUserTap,
  VoidCallback? onPkInvite,
  VoiceMgmtInitial initial = VoiceMgmtInitial.home,
}) {
  return CdsBottomSheet.showTransparent<void>(
    context: context,
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(ctx),
      child: _VoiceRoomManagementPanel(
        room: room,
        live: live,
        perms: perms,
        isOwner: isOwner,
        onUserTap: onUserTap,
        onPkInvite: onPkInvite,
        initial: initial,
      ),
    ),
  );
}

class _VoiceRoomManagementPanel extends ConsumerStatefulWidget {
  const _VoiceRoomManagementPanel({
    required this.room,
    required this.live,
    required this.perms,
    required this.isOwner,
    this.onUserTap,
    this.onPkInvite,
    this.initial = VoiceMgmtInitial.home,
  });

  final VoiceRoomEntity room;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final void Function(ChatRoomPresence user)? onUserTap;
  final VoidCallback? onPkInvite;
  final VoiceMgmtInitial initial;

  @override
  ConsumerState<_VoiceRoomManagementPanel> createState() =>
      _VoiceRoomManagementPanelState();
}

class _VoiceRoomManagementPanelState
    extends ConsumerState<_VoiceRoomManagementPanel> {
  late _MgmtView _view = _mapInitial(widget.initial);
  List<VoiceRoomBanEntry> _bans = const [];
  var _loadingBans = false;
  var _penaltyTab = _PenaltyTab.muted;
  List<VoiceRoomViolation> _violations = const [];
  var _loadingViolations = false;
  bool? _autoMod;

  static _MgmtView _mapInitial(VoiceMgmtInitial initial) => switch (initial) {
        VoiceMgmtInitial.home => _MgmtView.home,
        VoiceMgmtInitial.userMgmt => _MgmtView.userMgmt,
        VoiceMgmtInitial.users => _MgmtView.users,
        VoiceMgmtInitial.chatMgmt => _MgmtView.chatMgmt,
        VoiceMgmtInitial.roomMgmt => _MgmtView.roomMgmt,
        VoiceMgmtInitial.userSettings => _MgmtView.userSettings,
      };

  String get _liveRoomKey => widget.room.liveKey;

  VoiceRoomEntity get room {
    final base = widget.room;
    final live = _live;
    final synced =
        ref.watch(voiceRoomByIdProvider(base.liveKey)).valueOrNull ?? base;
    return synced.copyWith(
      seatCount: live.roomSeatCount ?? synced.seatCount,
      maxUsers: live.roomMaxUsers ?? synced.maxUsers,
    );
  }
  VoiceRoomPermissions get perms => widget.perms;
  bool get isOwner => widget.isOwner;

  VoiceRoomLiveController get _ctrl =>
      ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);

  VoiceRoomLiveState get _live =>
      ref.watch(voiceRoomLiveProvider(_liveRoomKey));

  Future<void> _snack(String text) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _loadBans() async {
    if (_loadingBans) return;
    setState(() => _loadingBans = true);
    try {
      final list = await _ctrl.fetchModerationBans();
      if (mounted) setState(() => _bans = list);
    } finally {
      if (mounted) setState(() => _loadingBans = false);
    }
  }

  Future<void> _loadViolations() async {
    if (_loadingViolations) return;
    setState(() => _loadingViolations = true);
    try {
      final list = await _ctrl.fetchModerationViolations();
      if (mounted) setState(() => _violations = list);
    } finally {
      if (mounted) setState(() => _loadingViolations = false);
    }
  }

  Future<void> _loadAutoMod() async {
    try {
      final key = widget.room.apiRoomKey.isNotEmpty
          ? widget.room.apiRoomKey
          : widget.room.id;
      final map = await ref.read(chatRoomRemoteProvider).fetchRoomSettings(key);
      final room = map['room'];
      final v = room is Map ? room['autoModeration'] : map['autoModeration'];
      if (mounted) setState(() => _autoMod = v is bool ? v : true);
    } catch (_) {
      if (mounted) setState(() => _autoMod = true);
    }
  }

  void _go(_MgmtView view) => setState(() => _view = view);

  /// Alt ekranın bağlı olduğu üst ekran.
  static _MgmtView _parentOf(_MgmtView v) => switch (v) {
        _MgmtView.users || _MgmtView.penalties => _MgmtView.userMgmt,
        _MgmtView.chatSettings || _MgmtView.autoMod => _MgmtView.chatMgmt,
        _MgmtView.roomInfo ||
        _MgmtView.vipSecurity ||
        _MgmtView.authority ||
        _MgmtView.seats ||
        _MgmtView.access ||
        _MgmtView.roomTools =>
          _MgmtView.roomMgmt,
        _MgmtView.userSound ||
        _MgmtView.userMic ||
        _MgmtView.userNotifications ||
        _MgmtView.userAppearance ||
        _MgmtView.userOther =>
          _MgmtView.userSettings,
        _ => _MgmtView.home,
      };

  void _back() {
    if (_view == _MgmtView.home) return;
    setState(() => _view = _parentOf(_view));
  }

  void _closeAndVoid(VoidCallback action) {
    final ctx = context;
    Navigator.pop(ctx);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctx.mounted) return;
      action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scroll) => VoiceGlass(
        borderRadius: 24,
        padding: EdgeInsets.fromLTRB(12, 12, 12, bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 8),
            Expanded(
              child: switch (_view) {
                _MgmtView.home => _homeView(scroll),
                _MgmtView.userMgmt => _userMgmtHub(scroll),
                _MgmtView.chatMgmt => _chatView(scroll),
                _MgmtView.roomMgmt => _roomView(scroll),
                _MgmtView.userSettings => _userSettingsView(scroll),
                _MgmtView.users => _usersView(scroll),
                _MgmtView.penalties => _penaltiesView(scroll),
                _MgmtView.chatSettings => _chatSettingsView(scroll),
                _MgmtView.roomInfo => _roomInfoView(scroll),
                _MgmtView.vipSecurity => _vipSecurityView(scroll),
                _MgmtView.authority => _authorityView(scroll),
                _MgmtView.seats => _seatsView(scroll),
                _MgmtView.access => _accessView(scroll),
                _MgmtView.roomTools => _roomToolsView(scroll),
                _MgmtView.userSound => _userSoundView(scroll),
                _MgmtView.userMic => _userMicView(scroll),
                _MgmtView.userNotifications => _userNotificationsView(scroll),
                _MgmtView.userAppearance => _userAppearanceView(scroll),
                _MgmtView.userOther => _userOtherView(scroll),
                _MgmtView.autoMod => _autoModView(scroll),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final title = switch (_view) {
      _MgmtView.home => 'Ayarlar',
      _MgmtView.userMgmt => 'Kullanıcı yönetimi',
      _MgmtView.chatMgmt => 'Sohbet yönetimi',
      _MgmtView.roomMgmt => 'Oda yönetimi',
      _MgmtView.userSettings => 'Kullanıcı ayarları',
      _MgmtView.users => 'Kullanıcılar',
      _MgmtView.penalties => 'Cezalar',
      _MgmtView.chatSettings => 'Sohbet ayarları',
      _MgmtView.roomInfo => 'Oda bilgileri',
      _MgmtView.vipSecurity => 'VIP / Şifreleme',
      _MgmtView.authority => 'Oda yetkileri',
      _MgmtView.seats => 'Koltuk / Seat yönetimi',
      _MgmtView.access => 'Odaya giriş kontrolü',
      _MgmtView.roomTools => 'Oda araçları',
      _MgmtView.userSound => 'Ses ayarları',
      _MgmtView.userMic => 'Mikrofon',
      _MgmtView.userNotifications => 'Bildirimler',
      _MgmtView.userAppearance => 'Görünüm',
      _MgmtView.userOther => 'Diğer ayarlar',
      _MgmtView.autoMod => 'Otomatik moderasyon',
    };
    return Row(
      children: [
        if (_view != _MgmtView.home)
          IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _homeView(ScrollController scroll) {
    void denied(String what) => _snack('$what için yetkiniz yok');
    return ListView(
      controller: scroll,
      children: [
        VoiceMgmtCard(
          icon: Icons.people_alt_rounded,
          title: 'Kullanıcı Yönetimi',
          subtitle: 'Odadaki kullanıcılar, cezalar, ses ve konuşma sırası',
          accent: VoiceRoomTokens.neonBlue,
          locked: !perms.canManageUsers,
          onTap: () {
            if (!perms.canManageUsers) return denied('Kullanıcı yönetimi');
            _loadBans();
            _go(_MgmtView.userMgmt);
          },
        ),
        VoiceMgmtCard(
          icon: Icons.chat_bubble_rounded,
          title: 'Sohbet Yönetimi',
          subtitle: 'Sohbet ayarları, yasaklı kelimeler, temizleme',
          accent: VoiceRoomTokens.neonPurple,
          locked: !perms.canManageChat,
          onTap: () {
            if (!perms.canManageChat) return denied('Sohbet yönetimi');
            _go(_MgmtView.chatMgmt);
          },
        ),
        VoiceMgmtCard(
          icon: Icons.home_work_rounded,
          title: 'Oda Yönetimi',
          subtitle: 'Oda bilgileri, yetkiler, koltuklar, giriş kontrolü',
          accent: VoiceRoomTokens.gold,
          locked: !perms.canManageRoomSettings,
          onTap: () {
            if (!perms.canManageRoomSettings) return denied('Oda yönetimi');
            _go(_MgmtView.roomMgmt);
          },
        ),
        VoiceMgmtCard(
          icon: Icons.manage_accounts_rounded,
          title: 'Kullanıcı Ayarları',
          subtitle: 'Ses, mikrofon, bildirimler ve görünüm (yalnızca sizin için)',
          accent: VoiceRoomTokens.neonPink,
          onTap: () => _go(_MgmtView.userSettings),
        ),
      ],
    );
  }

  Widget _userMgmtHub(ScrollController scroll) {
    return ListView(
      controller: scroll,
      children: [
        _hubTile(
          Icons.people_outline_rounded,
          'Odadaki Kullanıcılar',
          'Ses ver, koltuk, yetki, kanaldan at',
          () => _go(_MgmtView.users),
          badge: '${_live.presence.length}',
        ),
        _hubTile(
          Icons.gavel_rounded,
          'Cezalar',
          'Sessize alınanlar, banlananlar, geçici cezalar',
          () {
            _loadBans();
            _loadViolations();
            _go(_MgmtView.penalties);
          },
          accent: VoiceRoomTokens.neonPink,
        ),
        if (perms.canMuteUsers || isOwner)
          _hubTile(
            Icons.volume_off_rounded,
            'Sessize Alınmış Kullanıcılar',
            'Kalan süre ve sebep ile susturma listesi',
            () => _closeAndVoid(() {
              showVoiceMutedUsersSheet(
                context: context,
                ref: ref,
                roomKey: room.liveKey,
                presence: _live.presence,
                perms: perms,
              );
            }),
          ),
        _hubTile(
          Icons.mic_rounded,
          'Seste Olanlar',
          'Şu anda mikrofonu açık olanlar',
          () => _closeAndVoid(() {
            showVoiceRoomVoiceUsersSheet(
              context,
              ref: ref,
              liveKey: room.liveKey,
              onUserTap: widget.onUserTap,
            );
          }),
          accent: const Color(0xFF22C55E),
        ),
        if (perms.canAssignSeats || isOwner || perms.isSiteAdmin)
          _hubTile(
            Icons.record_voice_over_rounded,
            'Konuşma Sırası',
            'Kabul et, sıradan çıkar, sırayı değiştir',
            () => _closeAndVoid(() {
              showVoiceSpeakQueueSheet(
                context,
                ref,
                room: room,
                live: _live,
                perms: perms,
              );
            }),
            accent: VoiceRoomTokens.gold,
          ),
      ],
    );
  }

  Widget _hubTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color accent = VoiceRoomTokens.neonBlue,
    String? badge,
  }) {
    return VoiceMgmtCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      accent: accent,
      badge: badge,
    );
  }

  Widget _userSettingsView(ScrollController scroll) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final role = VoiceRoomMenuRole.label(perms, user: user, live: _live);
    return ListView(
      controller: scroll,
      children: [
        VoiceMgmtSectionTitle('Rumuzunuz: $role'),
        _hubTile(
          Icons.volume_up_rounded,
          'Ses Ayarları',
          'Ses kalitesi, gürültü azaltma, hoparlör',
          () => _go(_MgmtView.userSound),
        ),
        _hubTile(
          Icons.mic_rounded,
          'Mikrofon',
          'Konuşma isteği ve mikrofon durumu',
          () => _go(_MgmtView.userMic),
          accent: const Color(0xFF22C55E),
        ),
        _hubTile(
          Icons.notifications_rounded,
          'Bildirimler',
          'Giriş ve oda bildirim sesi',
          () => _go(_MgmtView.userNotifications),
          accent: VoiceRoomTokens.gold,
        ),
        _hubTile(
          Icons.palette_rounded,
          'Görünüm',
          'Efektler ve hediye animasyonları',
          () => _go(_MgmtView.userAppearance),
          accent: VoiceRoomTokens.neonPink,
        ),
        _hubTile(
          Icons.more_horiz_rounded,
          'Diğer Ayarlar',
          'Takma ad, jeton yükle, odayı şikayet et',
          () => _go(_MgmtView.userOther),
          accent: VoiceRoomTokens.neonPurple,
        ),
      ],
    );
  }

  Widget _userSoundView(ScrollController scroll) {
    return ListView(
      controller: scroll,
      children: [
        _hubTile(
          Icons.graphic_eq_rounded,
          'Ses kalitesi ve gürültü azaltma',
          'Bu cihaz için TRTC ses ayarları',
          () => _closeAndVoid(() => context.push('/settings/voice-audio')),
        ),
      ],
    );
  }

  Widget _userMicView(ScrollController scroll) {
    final ui = ref.watch(voiceRoomUiProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    return ListView(
      controller: scroll,
      children: [
        if (_selfOnSeat(user))
          const _EmptyHint('Koltuktasınız: mikrofonu oda ekranındaki düğmeden açıp kapatın.')
        else
          _hubTile(
            ui.requestSpeakPending
                ? Icons.hourglass_top_rounded
                : Icons.pan_tool_alt_rounded,
            ui.requestSpeakPending
                ? 'Konuşma isteğini iptal et'
                : 'Konuşma isteği gönder',
            ui.requestSpeakPending
                ? 'Moderatör onayı bekleniyor'
                : 'Onay sonrası koltuğa alınırsınız',
            () async {
              final pending = ui.requestSpeakPending;
              final err = pending
                  ? await _ctrl.cancelSpeakRequest()
                  : await _ctrl.requestSpeak();
              await _snack(
                err ??
                    (pending
                        ? 'Konuşma isteği iptal edildi'
                        : 'Konuşma isteği gönderildi'),
              );
            },
            accent: VoiceRoomTokens.neonPink,
          ),
      ],
    );
  }

  Widget _userNotificationsView(ScrollController scroll) {
    final ui = ref.watch(voiceRoomUiProvider);
    return ListView(
      controller: scroll,
      children: [
        SwitchListTile(
          title: const Text('Bildirim sesi'),
          subtitle: const Text('Giriş ve oda bildirimleri'),
          value: ui.chatNotificationSoundEnabled,
          onChanged: (_) {
            ref.read(voiceRoomUiProvider.notifier).toggleChatNotificationSound();
          },
        ),
      ],
    );
  }

  Widget _userAppearanceView(ScrollController scroll) {
    final ui = ref.watch(voiceRoomUiProvider);
    return ListView(
      controller: scroll,
      children: [
        _hubTile(
          Icons.auto_awesome_rounded,
          'Efektler ve görünüm',
          'Giriş efektleri ve oda görünümü',
          () => _closeAndVoid(() => showVoiceEffectsSheet(context, ref)),
          accent: VoiceRoomTokens.neonPink,
        ),
        SwitchListTile(
          title: const Text('Hediye animasyonları'),
          value: ui.giftAnimationsEnabled,
          onChanged: (_) {
            ref.read(voiceRoomUiProvider.notifier).toggleGiftAnimations();
          },
        ),
      ],
    );
  }

  Widget _userOtherView(ScrollController scroll) {
    final jetonTopUpLabel = economyJetonTopUpShortLabel(ref);
    return ListView(
      controller: scroll,
      children: [
        _hubTile(
          Icons.edit_rounded,
          'Takma adı değiştir',
          'Bu odada sohbette görünecek ad',
          () async {
            await _changeNickname();
            if (mounted) Navigator.pop(context);
          },
        ),
        _hubTile(
          Icons.diamond_rounded,
          jetonTopUpLabel,
          'Cüzdan ve jeton paketleri',
          () => _closeAndVoid(() => openJetonStore(context, ref: ref)),
          accent: VoiceRoomTokens.gold,
        ),
        _hubTile(
          Icons.flag_rounded,
          'Odayı şikayet et',
          'Uygunsuz içerik veya davranış bildir',
          () {
            final roomKey = widget.room.apiRoomKey.isNotEmpty
                ? widget.room.apiRoomKey
                : widget.room.id;
            _closeAndVoid(
              () => openReportFlow(
                context,
                ReportTarget(
                  type: ReportTargetType.voiceRoom,
                  targetId: roomKey,
                  displayTitle: widget.room.displayTitle,
                  contextLabel: 'Sesli oda',
                ),
              ),
            );
          },
          accent: VoiceRoomTokens.neonPink,
        ),
      ],
    );
  }

  Widget _chatView(ScrollController scroll) {
    final canMod = perms.canModerate || isOwner || perms.isSiteAdmin;
    return ListView(
      controller: scroll,
      children: [
        _hubTile(
          Icons.forum_rounded,
          'Sohbet Ayarları',
          'Oda sessize alma, komutlar, sahiplik devri',
          () => _go(_MgmtView.chatSettings),
          accent: VoiceRoomTokens.neonPurple,
        ),
        if (perms.canMuteUsers || isOwner || canMod)
          _hubTile(
            Icons.volume_off_rounded,
            'Mute Edilenler',
            'Susturulan kullanıcılar ve kalan süre',
            () => _closeAndVoid(() {
              showVoiceMutedUsersSheet(
                context: context,
                ref: ref,
                roomKey: room.liveKey,
                presence: _live.presence,
                perms: perms,
              );
            }),
          ),
        if (canMod)
          _hubTile(
            Icons.block_rounded,
            'Yasaklı Kelimeler',
            '${_live.bannedWords.length} kelime — ekle / kaldır',
            () => _closeAndVoid(() {
              showVoiceRoomToolsSheet(
                context,
                ref,
                room: room,
                perms: perms,
                isOwner: isOwner,
              );
            }),
            accent: VoiceRoomTokens.neonPink,
          ),
        if (canMod)
          _hubTile(
            Icons.shield_rounded,
            'Otomatik Moderasyon',
            'GirLive Bot: uyarı, mute ve ban kuralları',
            () {
              _loadAutoMod();
              _go(_MgmtView.autoMod);
            },
            accent: const Color(0xFF22C55E),
          ),
        if (canMod)
          _hubTile(
            Icons.cleaning_services_rounded,
            'Sohbeti Temizle',
            'Tüm mesajları siler',
            _confirmClearChat,
            accent: VoiceRoomTokens.gold,
          ),
      ],
    );
  }

  Widget _autoModView(ScrollController scroll) {
    final canToggle = isOwner || perms.canManageRoom || perms.isSiteAdmin;
    final on = _autoMod ?? true;
    const ladder = [
      ('LOW', 'Hafif ihlal', 'Uyarı'),
      ('MEDIUM', 'Orta ihlal', 'Uyarı + geçici sessize alma'),
      ('HIGH', 'Ağır ihlal', 'Odadan atma'),
      ('CRITICAL', 'Çok ağır ihlal', 'Ban'),
    ];
    return ListView(
      controller: scroll,
      children: [
        SwitchListTile(
          title: const Text('GirLive Bot otomatik moderasyon'),
          subtitle: Text(
            _autoMod == null
                ? 'Yükleniyor…'
                : (on
                    ? 'Açık — mesajlar sunucuda denetlenir'
                    : 'Kapalı — bu odada otomatik işlem yapılmaz'),
          ),
          value: on,
          onChanged: (_autoMod == null || !canToggle)
              ? null
              : (v) async {
                  final err = await _ctrl.setAutoModeration(v);
                  if (err == null && mounted) setState(() => _autoMod = v);
                  await _snack(err ?? (v ? 'Otomatik moderasyon açıldı' : 'Otomatik moderasyon kapatıldı'));
                },
        ),
        const VoiceMgmtSectionTitle('Ciddiyet seviyeleri'),
        for (final l in ladder)
          ListTile(
            dense: true,
            leading: Text(
              l.$1,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
            ),
            title: Text(l.$2),
            subtitle: Text(l.$3),
          ),
        const _EmptyHint(
          'Tek kelimeyle doğrudan ban verilmez: tekrarlayan ihlaller kademeli '
          'olarak yükselir. Oda sahibi ve yöneticiler etkilenmez. Kelime listesi '
          've eylem eşlemesi yönetici panelinden değiştirilebilir.',
        ),
      ],
    );
  }

  Future<void> _confirmClearChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sohbeti temizle'),
        content: const Text('Tüm mesajlar silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await _ctrl.clearChatAsModerator();
    if (!mounted) return;
    Navigator.pop(context);
    await _snack(err ?? 'Sohbet temizlendi');
  }

  Widget _chatSettingsView(ScrollController scroll) {
    final roomMuted = _live.roomMuted;
    final canMod = perms.canModerate || isOwner || perms.isSiteAdmin;
    return ListView(
      controller: scroll,
      children: [
        if (canMod || perms.canMuteRoom)
          SwitchListTile(
            title: const Text('Odayı sessize al'),
            subtitle: Text(roomMuted ? 'Oda şu an sessiz' : 'Oda sesi açık'),
            value: roomMuted,
            onChanged: (v) async {
              final err = await _ctrl.toggleRoomMute(mute: v);
              await _snack(
                err ?? (v ? 'Oda sessize alındı' : 'Oda sesi açıldı'),
              );
            },
          ),
        if (canMod || isOwner)
          _hubTile(
            Icons.terminal_rounded,
            'Oda komutları',
            '!duyuru, !kick, !ban, müzik isteği',
            () => _closeAndVoid(() {
              showVoiceRoomCommandsPanel(
                context,
                ref,
                room: room,
                perms: perms,
                isOwner: isOwner,
              );
            }),
          ),
      ],
    );
  }

  Future<void> _pickUserForTransfer(ScrollController scroll) async {
    final users = _live.presence
        .where((p) => p.id != ref.read(authControllerProvider).valueOrNull?.id)
        .toList();
    if (users.isEmpty) {
      await _snack('Devredilecek kullanıcı yok');
      return;
    }
    final picked = await showModalBottomSheet<ChatRoomPresence>(
      context: context,
      backgroundColor: const Color(0xFF12082A),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: ListPerf.nestedListHeight(
            itemCount: users.length,
            itemExtent: 56,
          ).clamp(56, 420),
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              return ListTile(
                leading: VoiceNeonAvatar(url: u.image, size: 36),
                title: Text(u.displayName, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, u),
              );
            },
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sahipligi devret'),
        content: Text('${picked.displayName} oda sahibi yapılsın mı?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Devret')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(chatRoomRemoteProvider).transferOwnership(
            roomKey: widget.room.apiRoomKey.isNotEmpty
                ? widget.room.apiRoomKey
                : widget.room.id,
            newOwnerId: picked.id,
          );
      await _ctrl.refresh();
      await _snack('Oda ${picked.displayName} kullanıcısına devredildi');
    } catch (e) {
      await _snack(ApiException.userMessage(e));
    }
  }

  Future<void> _changeNickname() async {
    final controller = TextEditingController();
    try {
      final nick = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Takma ad (rumuz)'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Sohbette görünecek ad',
              border: OutlineInputBorder(),
            ),
            maxLength: 32,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
      if (nick == null) return;
      final err = await _ctrl.updateRoomNickname(nick);
      await _snack(err ?? 'Takma ad güncellendi');
    } finally {
      controller.dispose();
    }
  }

  Widget _usersView(ScrollController scroll) {
    final users = [..._live.presence]
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    if (users.isEmpty) {
      return const Center(child: Text('Odada kullanıcı yok'));
    }
    return ListView.builder(
      controller: scroll,
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i];
        final sym = u.roleSymbol?.trim();
        final isVip = (sym == 'V' || sym == 'v') ||
            ((u.membership ?? '').trim().isNotEmpty);
        final seat = u.seatIndex != null
            ? 'Koltuk ${u.seatIndex! + 1}'
            : 'Dinleyici';
        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              VoiceNeonAvatar(url: u.image, size: 40),
              Positioned(
                right: -1,
                bottom: -1,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: u.isOnline
                      ? const Color(0xFF22C55E)
                      : Colors.white38,
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  u.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (u.level != null) ...[
                const SizedBox(width: 6),
                Text(
                  'Sv.${u.level}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: VoiceRoomTokens.neonBlue,
                  ),
                ),
              ],
              if (isVip) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: VoiceRoomTokens.gold,
                ),
              ],
            ],
          ),
          subtitle: Text(
            [
              if (sym != null && sym.isNotEmpty) sym,
              u.chatRole ?? 'dinleyici',
              seat,
              if (u.isMuted) 'susturulmuş',
            ].join(' · '),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                u.micOpen ? Icons.mic_rounded : Icons.mic_off_rounded,
                size: 20,
                color: u.micOpen
                    ? const Color(0xFF22C55E)
                    : Colors.white.withValues(alpha: 0.4),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          onTap: () => _openUserModeration(u),
        );
      },
    );
  }

  void _openUserModeration(ChatRoomPresence u) {
    if (!VoiceRoomUserActions.canOpenModerationSheet(perms)) {
      widget.onUserTap?.call(u);
      return;
    }
    final target = VoiceRoomModerationTarget.fromPresence(u);
    final isDj = room.djUserIds.contains(u.id) ||
        _live.dj.djUsers.any((d) => d.id == u.id);
    _closeAndVoid(() {
      showVoiceRoomModerationSheet(
        context: context,
        ref: ref,
        room: room,
        targetUser: target,
        isOwnerOrMod: true,
        perms: perms,
        isOwner: isOwner,
        isTargetDj: isDj,
      );
    });
  }

  Widget _roomView(ScrollController scroll) {
    final canEdit = isOwner || perms.canManageRoom;
    return ListView(
      controller: scroll,
      children: [
        _hubTile(
          Icons.info_rounded,
          'Oda Bilgileri',
          'Ad, açıklama, kural, kategori ve arkaplan',
          () => _go(_MgmtView.roomInfo),
        ),
        // Şifreleme yalnızca VIP odalarda (roomType == VIP) görünür.
        if (room.isStrictVipRoom && (canEdit || perms.isSiteAdmin))
          _hubTile(
            Icons.lock_rounded,
            'VIP / Şifreleme',
            room.hasPassword == true
                ? 'Şifreli oda açık — şifreyi değiştir veya kaldır'
                : 'Odaya giriş için şifre belirle',
            () => _go(_MgmtView.vipSecurity),
            accent: VoiceRoomTokens.gold,
          ),
        _hubTile(
          Icons.admin_panel_settings_rounded,
          'Oda Yetkileri',
          'Moderatör ve DJ atama, sahiplik devri',
          () => _go(_MgmtView.authority),
          accent: VoiceRoomTokens.neonPurple,
        ),
        _hubTile(
          Icons.event_seat_rounded,
          'Koltuk / Seat Yönetimi',
          'Koltuk sayısı, konuşma sırası, seste olanlar',
          () => _go(_MgmtView.seats),
          accent: const Color(0xFF22C55E),
        ),
        _hubTile(
          Icons.door_front_door_rounded,
          'Odaya Giriş Kontrolü',
          'Banlananlar ve giriş izinleri',
          () => _go(_MgmtView.access),
          accent: VoiceRoomTokens.neonPink,
        ),
        _hubTile(
          Icons.apps_rounded,
          'Oda Araçları',
          'PK, müzik, hediye savaşı ve hedefi',
          () => _go(_MgmtView.roomTools),
          accent: VoiceRoomTokens.neonBlue,
        ),
      ],
    );
  }

  Widget _roomInfoView(ScrollController scroll) {
    final canBg = perms.canChangeBackground || isOwner;
    final canEdit = isOwner || perms.canManageRoom;
    return ListView(
      controller: scroll,
      children: [
        if (canEdit) ...[
          _hubTile(
            Icons.edit_rounded,
            'Oda adı ve açıklama',
            room.displayTitle,
            _editRoomDetails,
          ),
          _hubTile(
            Icons.category_rounded,
            'Kategori',
            voiceRoomCategoryLabel(room.category),
            _pickCategory,
            accent: VoiceRoomTokens.neonPurple,
          ),
        ],
        if (canBg &&
            !voiceRoomBackgroundUnlocked(room, isSiteAdmin: perms.isSiteAdmin))
          VoiceMgmtCard(
            icon: Icons.photo_library_rounded,
            title: 'Arkaplan',
            subtitle: voiceRoomBackgroundLockedMessage,
            locked: true,
            onTap: () => _snack(voiceRoomBackgroundLockedMessage),
          )
        else if (canBg)
          _hubTile(
            Icons.photo_library_rounded,
            'Arkaplan',
            'Sunucudaki hazır görseller veya yükle',
            () {
              Navigator.pop(context);
              showVoiceRoomBackgroundSheet(context, ref, room: room);
            },
            accent: const Color(0xFF22C55E),
          ),
        if (!canEdit && !canBg) const _EmptyHint('Bu bölüm için yetkiniz yok'),
      ],
    );
  }

  Widget _vipSecurityView(ScrollController scroll) {
    final enabled = room.hasPassword == true;
    return ListView(
      controller: scroll,
      children: [
        SwitchListTile(
          title: const Text('Şifreli Oda'),
          subtitle: Text(
            enabled
                ? 'Açık — girişte şifre sorulur (3 deneme hakkı)'
                : 'Kapalı — herkes girebilir',
          ),
          value: enabled,
          onChanged: (v) async {
            if (v) {
              await _setRoomPassword();
            } else {
              final err = await _ctrl.setRoomPassword(password: null);
              await _snack(err ?? 'Şifre kaldırıldı');
            }
          },
        ),
        if (enabled)
          _hubTile(
            Icons.key_rounded,
            'Şifreyi değiştir',
            'Yeni şifre belirle',
            _setRoomPassword,
            accent: VoiceRoomTokens.gold,
          ),
      ],
    );
  }

  Widget _authorityView(ScrollController scroll) {
    return ListView(
      controller: scroll,
      children: [
        _hubTile(
          Icons.people_alt_rounded,
          'Moderatör / yetki ata',
          'Kullanıcı seç: moderatör, DJ, koltuk yetkisi',
          () => _go(_MgmtView.users),
        ),
        if (perms.canManageDj || isOwner || perms.canModerate)
          _hubTile(
            Icons.library_music_rounded,
            'DJ yönetimi',
            'DJ ata ve müziği kontrol et',
            () => _closeAndVoid(() {
              showVoiceMusicControlHub(
                context,
                ref,
                room: room,
                perms: perms,
                isOwner: isOwner,
              );
            }),
            accent: VoiceRoomTokens.neonPink,
          ),
        if (isOwner)
          _hubTile(
            Icons.swap_horiz_rounded,
            'Sahipliği devret',
            'Odayı başka bir kullanıcıya ver',
            () => _pickUserForTransfer(ScrollController()),
            accent: VoiceRoomTokens.gold,
          ),
      ],
    );
  }

  Widget _seatsView(ScrollController scroll) {
    return ListView(
      controller: scroll,
      children: [
        if (isOwner || perms.canManageRoom)
          _hubTile(
            Icons.event_seat_rounded,
            'Koltuk sayısı',
            '${_live.roomSeatCount ?? room.seatCount ?? kDefaultVoiceSeatCount} mikrofon',
            _pickSeatCount,
          ),
        if (perms.canAssignSeats || isOwner || perms.isSiteAdmin)
          _hubTile(
            Icons.record_voice_over_rounded,
            'Konuşma sırası',
            'Kabul et, sıradan çıkar, sırayı değiştir',
            () => _closeAndVoid(() {
              showVoiceSpeakQueueSheet(
                context,
                ref,
                room: room,
                live: _live,
                perms: perms,
              );
            }),
            accent: VoiceRoomTokens.gold,
          ),
        _hubTile(
          Icons.mic_rounded,
          'Seste olanlar',
          'Şu anda mikrofonu açık olanlar',
          () => _closeAndVoid(() {
            showVoiceRoomVoiceUsersSheet(
              context,
              ref: ref,
              liveKey: room.liveKey,
              onUserTap: widget.onUserTap,
            );
          }),
          accent: const Color(0xFF22C55E),
        ),
      ],
    );
  }

  Widget _accessView(ScrollController scroll) {
    return ListView(
      controller: scroll,
      children: [
        _hubTile(
          Icons.block_rounded,
          'Banlananlar',
          'Odaya girişi yasaklı kullanıcılar',
          () {
            _loadBans();
            setState(() {
              _penaltyTab = _PenaltyTab.banned;
              _view = _MgmtView.penalties;
            });
          },
          accent: VoiceRoomTokens.neonPink,
        ),
      ],
    );
  }

  Widget _roomToolsView(ScrollController scroll) {
    final pk = ref.watch(pkBattleForRoomProvider(room));
    final pkLive = isPkBattleLive(pk);
    final pkFeatureOn = ref.watch(pkFeatureEnabledProvider);
    final roomKey = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    return ListView(
      controller: scroll,
      children: [
        if (pkFeatureOn)
          _hubTile(
            pkLive ? Icons.flash_on_rounded : Icons.sports_mma_rounded,
            pkLive ? 'PK savaşı' : 'PK daveti',
            pkLive ? 'Devam eden PK ekranına git' : 'Başka bir odayı PK\'ya davet et',
            () => _closeAndVoid(() {
              if (pkLive) {
                context.push('/voice-room/$roomKey/pk', extra: room);
              } else if (widget.onPkInvite != null) {
                widget.onPkInvite!();
              } else {
                openVoicePkInviteSheet(context, ref, room);
              }
            }),
            accent: VoiceRoomTokens.neonPink,
          ),
        if (pkFeatureOn && isOwner && !pkLive)
          _hubTile(
            Icons.groups_rounded,
            'Oda içi PK (takım)',
            'Odadaki kullanıcılarla 2 takım, en fazla 4+4',
            () => _closeAndVoid(() {
              showVoiceInRoomPkSheet(
                context,
                ref,
                room: room,
                presence: _live.presence,
              );
            }),
            accent: VoiceRoomTokens.neonPink,
          ),
        if (perms.canManageDj || isOwner || perms.canModerate)
          _hubTile(
            Icons.library_music_rounded,
            'Müzik kontrolü',
            'Şarkı isteği (video/ses) ve DJ',
            () => _closeAndVoid(() {
              showVoiceMusicControlHub(
                context,
                ref,
                room: room,
                perms: perms,
                isOwner: isOwner,
              );
            }),
          ),
        if (isOwner || perms.canManageRoom)
          _hubTile(
            Icons.tune_rounded,
            'Müzik ayarları',
            'DJ: ${_live.dj.musicEnabled ? "açık" : "kapalı"} · '
                '${_live.dj.musicRequestCost} $jetonLabel · kuyruk ${_live.dj.maxMusicQueue}',
            () => _closeAndVoid(() {
              showVoiceRoomMusicSettingsDialog(context, ref, room: room);
            }),
          ),
        _hubTile(
          Icons.music_note_rounded,
          'Şarkı isteği',
          'Video (CDN) veya ses (YouTube API)',
          () => _closeAndVoid(() {
            showVoiceYoutubeSongSheet(context, ref, room: room);
          }),
          accent: VoiceRoomTokens.neonPurple,
        ),
        if (isOwner || perms.canManageRoom) ...[
          _hubTile(
            Icons.local_fire_department_rounded,
            'Hediye Savaşı Başlat',
            'Koltuktakiler yarışır (1/3/5/10 dk)',
            _startGiftBattle,
            accent: const Color(0xFFFF7043),
          ),
          _hubTile(
            Icons.flag_rounded,
            'Hediye Hedefi Belirle',
            'Toplanınca kutlama tetiklenir',
            _startGiftGoal,
            accent: const Color(0xFF66E36F),
          ),
        ],
      ],
    );
  }

  Future<void> _startGiftBattle() async {
    // Katılımcı: önce koltuktakiler; koltuk verisi yoksa/azsa odadaki tüm
    // kullanıcılar. (seatIndex her odada dolmayabiliyor → eskiden hep "2
    // koltukta kullanıcı" deyip başlamıyordu.)
    final present =
        widget.live.presence.where((p) => p.id.isNotEmpty).toList();
    final seatedUsers =
        present.where((p) => p.seatIndex != null).toList();
    final seated = seatedUsers.length >= 2 ? seatedUsers : present;
    if (seated.length < 2) {
      await _snack('Savaş için odada en az 2 kişi olmalı');
      return;
    }
    final duration = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF12082A),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Savaş süresi',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ),
            for (final opt in const [
              (60, '1 dakika'),
              (180, '3 dakika'),
              (300, '5 dakika'),
              (600, '10 dakika'),
            ])
              ListTile(
                leading: const Icon(Icons.timer_rounded, color: Colors.white70),
                title: Text(opt.$2, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, opt.$1),
              ),
          ],
        ),
      ),
    );
    if (duration == null || !mounted) return;
    try {
      final contextId = widget.room.apiRoomKey.isNotEmpty
          ? widget.room.apiRoomKey
          : widget.room.id;
      final battle = await ref.read(giftBattleRemoteProvider).startBattle(
            context: 'voice_room',
            contextId: contextId,
            durationSec: duration,
            participants: [
              for (final p in seated)
                (id: p.id, name: p.displayName),
            ],
          );
      if (battle != null) {
        ref
            .read(giftBattleProvider(
                    (context: 'voice_room', contextId: contextId))
                .notifier)
            .adopt(battle);
      }
      await _snack('Hediye savaşı başladı!');
    } catch (e) {
      await _snack(ApiException.userMessage(e));
    }
  }

  Future<void> _startGiftGoal() async {
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    final picked = await showVoiceGiftGoalStartModal(context, ref);
    if (picked == null || !mounted) return;
    try {
      final contextId = widget.room.apiRoomKey.isNotEmpty
          ? widget.room.apiRoomKey
          : widget.room.id;
      final goal = await ref.read(giftGoalRemoteProvider).createGoal(
            context: 'voice_room',
            contextId: contextId,
            title: 'Hedef: ${_fmtCoins(picked.targetAmount)} $jetonLabel',
            targetAmount: picked.targetAmount,
            durationMinutes: picked.durationMinutes,
          );
      if (goal != null) {
        ref
            .read(giftGoalProvider(
                    (context: 'voice_room', contextId: contextId))
                .notifier)
            .adopt(goal, fallbackDurationMinutes: picked.durationMinutes);
      }
      await _snack('Hediye hedefi belirlendi (${picked.durationMinutes} dk)!');
    } catch (e) {
      await _snack(ApiException.userMessage(e));
    }
  }

  static String _fmtCoins(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }

  bool _selfOnSeat(UserEntity? user) {
    final id = user?.id;
    if (id == null || id.isEmpty) return false;
    for (final p in _live.presence) {
      if (p.id == id && p.seatIndex != null) return true;
    }
    return false;
  }

  Future<void> _editRoomDetails() async {
    final nameCtrl = TextEditingController(text: room.displayTitle);
    final descCtrl = TextEditingController(text: room.descTr ?? '');
    final rulesCtrl = TextEditingController(text: room.rulesTr ?? '');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Oda bilgileri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Oda adı',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 64,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 280,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rulesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Oda kuralları',
                    border: OutlineInputBorder(),
                    hintText: 'Sohbette kayan kurallar metni',
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      final err = await _ctrl.updateRoomDetails(
        name: nameCtrl.text,
        description: descCtrl.text,
        rules: rulesCtrl.text,
      );
      await _snack(err ?? 'Oda bilgileri güncellendi');
    } finally {
      nameCtrl.dispose();
      descCtrl.dispose();
      rulesCtrl.dispose();
    }
  }


  Future<void> _pickCategory() async {
    final current = normalizeVoiceRoomCategory(room.category);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Oda kategorisi'),
        children: kVoiceRoomAssignableCategories
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, c.id),
                child: Row(
                  children: [
                    if (c.id == current)
                      const Icon(Icons.check_rounded, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text(c.label),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (picked == null || picked == current) return;
    final err = await _ctrl.updateRoomCategory(picked);
    await _snack(
      err ?? 'Kategori ${voiceRoomCategoryLabel(picked)} olarak güncellendi',
    );
  }

  Future<void> _pickSeatCount() async {
    final current =
        _live.roomSeatCount ?? room.seatCount ?? kDefaultVoiceSeatCount;
    final options = List<int>.generate(15, (i) => i + 1);
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Koltuk sayısı'),
        children: options
            .map(
              (n) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, n),
                child: Row(
                  children: [
                    if (n == current)
                      const Icon(Icons.check_rounded, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text('$n mikrofon'),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (picked == null || picked == current) return;
    final err = await _ctrl.updateRoomCapacity(seatCount: picked);
    await _snack(err ?? 'Koltuk sayısı $picked olarak güncellendi');
  }

  Future<void> _setRoomPassword() async {
    final controller = TextEditingController();
    try {
      final pass = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Oda şifresi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni şifre (boş = kaldır)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
      if (pass == null) return;
      final trimmed = pass.trim();
      if (trimmed.isNotEmpty && trimmed.length < 4) {
        await _snack('Şifre en az 4 karakter olmalı');
        return;
      }
      final err = await _ctrl.setRoomPassword(
        password: pass.trim().isEmpty ? null : pass.trim(),
      );
      await _snack(err ?? (pass.trim().isEmpty ? 'Şifre kaldırıldı' : 'Oda şifresi kaydedildi'));
    } finally {
      controller.dispose();
    }
  }

  Widget _penaltiesView(ScrollController scroll) {
    final muted = _live.presence.where((p) => p.isMuted).toList();
    final now = DateTime.now();
    final temporary = _bans
        .where((b) => b.expiresAt != null && b.expiresAt!.isAfter(now))
        .toList();
    final permanent = _bans.where((b) => b.expiresAt == null).toList();
    final banned = _penaltyTab == _PenaltyTab.temporary ? temporary : permanent;

    return ListView(
      controller: scroll,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Wrap(
            spacing: 8,
            children: [
              for (final t in const [
                (_PenaltyTab.muted, 'Sessize alınanlar'),
                (_PenaltyTab.banned, 'Banlananlar'),
                (_PenaltyTab.temporary, 'Geçici cezalar'),
                (_PenaltyTab.warnings, 'Uyarılar'),
              ])
                ChoiceChip(
                  label: Text(t.$2),
                  selected: _penaltyTab == t.$1,
                  onSelected: (_) => setState(() => _penaltyTab = t.$1),
                ),
            ],
          ),
        ),
        if (_penaltyTab == _PenaltyTab.muted) ...[
          if (muted.isEmpty)
            const _EmptyHint('Sessize alınmış kullanıcı yok')
          else
            ...muted.map(
              (u) => ListTile(
                leading: VoiceNeonAvatar(url: u.image, size: 36),
                title: Text(u.displayName),
                trailing: (perms.canMuteUsers || isOwner)
                    ? TextButton(
                        onPressed: () async {
                          final err =
                              await _ctrl.unmuteUserModeration(userId: u.id);
                          await _snack(err ?? 'Susturma kaldırıldı');
                        },
                        child: const Text('Sessizi Kaldır'),
                      )
                    : null,
              ),
            ),
        ] else if (_penaltyTab == _PenaltyTab.warnings) ...[
          if (_loadingViolations)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_violations.where((v) => v.isWarning).isEmpty)
            const _EmptyHint('Uyarı kaydı yok')
          else
            ..._violations.where((v) => v.isWarning).map(
                  (v) => ListTile(
                    leading: VoiceNeonAvatar(url: v.imageUrl, size: 36),
                    title: Text(v.userLabel),
                    subtitle: Text(
                      [
                        v.actionLabel,
                        v.severity,
                        if ((v.word ?? '').isNotEmpty) '"${v.word}"',
                      ].join(' · '),
                    ),
                  ),
                ),
        ] else ...[
          if (_loadingBans)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (banned.isEmpty)
            _EmptyHint(
              _penaltyTab == _PenaltyTab.temporary
                  ? 'Süreli ceza yok'
                  : 'Banlı kullanıcı yok',
            )
          else
            ...banned.map(
              (b) => ListTile(
                leading: VoiceNeonAvatar(url: b.imageUrl, size: 36),
                title: Text(b.displayName),
                subtitle: Text(
                  [
                    if ((b.reason ?? '').isNotEmpty) b.reason!,
                    if (b.expiresAt != null)
                      'Kalan: ${_remaining(b.expiresAt!)}',
                  ].join(' · '),
                ),
                trailing: (perms.canBanUsers || isOwner)
                    ? TextButton(
                        onPressed: () async {
                          final err = await _ctrl.unbanUserModeration(
                            userId: b.userId,
                          );
                          await _loadBans();
                          await _snack(err ?? 'Ban kaldırıldı');
                        },
                        child: const Text('Ban kaldır'),
                      )
                    : null,
              ),
            ),
        ],
        if (perms.canKickUsers || isOwner)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () => _go(_MgmtView.users),
              icon: const Icon(Icons.people_outline_rounded),
              label: const Text('Kullanıcı seç ve kanaldan at'),
            ),
          ),
      ],
    );
  }

  static String _remaining(DateTime until) {
    final d = until.difference(DateTime.now());
    if (d.inDays >= 1) return '${d.inDays} gün';
    if (d.inHours >= 1) return '${d.inHours} sa';
    return '${d.inMinutes.clamp(1, 59)} dk';
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
      ),
    );
  }
}
