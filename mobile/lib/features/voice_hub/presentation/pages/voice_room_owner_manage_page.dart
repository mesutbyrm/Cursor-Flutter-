import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../search/domain/entities/search_user_entity.dart';
import '../../../search/presentation/providers/search_providers.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../providers/chat_room_providers.dart';
import '../utils/voice_room_category_catalog.dart';
import '../utils/voice_room_seat_capacity.dart';

/// `GET /api/chat/rooms/{id}/settings` — sahip / kurucu görür.
final ownerRoomSettingsProvider = FutureProvider.autoDispose
    .family<OwnerRoomSettings, String>((ref, roomKey) async {
  final raw = await ref.read(chatRoomRemoteProvider).fetchRoomSettings(roomKey);
  return OwnerRoomSettings.fromJson(raw);
});

class OwnerRoomSettings {
  const OwnerRoomSettings({
    required this.name,
    required this.description,
    required this.category,
    this.backgroundImage,
    this.hasPassword = false,
    this.seatCount,
    this.welcomeMessage,
    this.pinnedAnnouncement,
    this.isMuted = false,
    this.djUserIds = const [],
    this.commissionPercent = 0,
  });

  factory OwnerRoomSettings.fromJson(Map<String, dynamic> j) {
    String? str(String k) {
      final v = j[k]?.toString().trim();
      return v == null || v.isEmpty || v == 'null' ? null : v;
    }

    final tags = str('tags');
    final firstTag = tags?.split(',').first.trim();
    return OwnerRoomSettings(
      name: str('nameTr') ?? '',
      description: str('descTr') ?? '',
      category: firstTag,
      backgroundImage: str('backgroundImage'),
      hasPassword: str('password') != null,
      seatCount: j['seatCount'] is num ? (j['seatCount'] as num).toInt() : null,
      welcomeMessage: str('welcomeMessage'),
      pinnedAnnouncement: str('pinnedAnnouncement'),
      isMuted: j['isMuted'] == true,
      djUserIds: parseDjUserIds(j['djUserIds']),
      commissionPercent: j['giftCommissionPercent'] is num
          ? (j['giftCommissionPercent'] as num).toInt()
          : 0,
    );
  }

  static List<String> parseDjUserIds(dynamic raw) {
    if (raw is List) return raw.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => '$e').where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  final String name;
  final String description;
  final String? category;
  final String? backgroundImage;
  final bool hasPassword;
  final int? seatCount;
  final String? welcomeMessage;
  final String? pinnedAnnouncement;
  final bool isMuted;
  final List<String> djUserIds;
  final int commissionPercent;
}

Future<void> openVoiceRoomOwnerManagePage(
  BuildContext context,
  VoiceRoomEntity room,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => VoiceRoomOwnerManagePage(room: room),
    ),
  );
}

/// Oda sahibinin odaya girmeden tüm ayarları yönettiği sayfa.
class VoiceRoomOwnerManagePage extends ConsumerStatefulWidget {
  const VoiceRoomOwnerManagePage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VoiceRoomOwnerManagePage> createState() =>
      _VoiceRoomOwnerManagePageState();
}

class _VoiceRoomOwnerManagePageState
    extends ConsumerState<VoiceRoomOwnerManagePage> {
  static const _bg = Color(0xFF0E0A1A);
  static const _card = Color(0xFF1B1430);
  static const _muted = Color(0xFFC9C3DA);
  static const _accent = Color(0xFFB794F6);

  var _busy = false;

  String get _key => widget.room.apiRoomKey;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() action, String ok) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(ownerRoomSettingsProvider(_key));
      ref.invalidate(voiceRoomByIdProvider(_key));
      ref.invalidate(voiceRoomsListNotifierProvider);
      _snack(ok);
    } catch (e) {
      _snack(ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _patch(Map<String, dynamic> data, String ok) =>
      _run(() => ref.read(chatRoomRemoteProvider).patchRoomSettings(_key, data), ok);

  Future<String?> _textDialog({
    required String title,
    String initial = '',
    String hint = '',
    int maxLines = 1,
    int maxLength = 120,
    bool obscure = false,
  }) async {
    final ctrl = TextEditingController(text: initial);
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            obscureText: obscure,
            maxLines: obscure ? 1 : maxLines,
            maxLength: maxLength,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _editName(OwnerRoomSettings s) async {
    final v = await _textDialog(title: 'Oda adı', initial: s.name, maxLength: 40);
    if (v == null || v.isEmpty) return;
    await _patch({'nameTr': v}, 'Oda adı güncellendi');
  }

  Future<void> _editDescription(OwnerRoomSettings s) async {
    final v = await _textDialog(
      title: 'Açıklama',
      initial: s.description,
      maxLines: 3,
      maxLength: 200,
    );
    if (v == null) return;
    await _patch({'descTr': v}, 'Açıklama güncellendi');
  }

  Future<void> _pickCategory(OwnerRoomSettings s) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _card,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in kVoiceRoomAssignableCategories)
              ListTile(
                title: Text(c.label, style: const TextStyle(color: Colors.white)),
                trailing: c.id == s.category
                    ? const Icon(Icons.check_rounded, color: _accent)
                    : null,
                onTap: () => Navigator.pop(ctx, c.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _patch({'tags': picked}, 'Kategori: ${voiceRoomCategoryLabel(picked)}');
  }

  Future<void> _pickBackground() async {
    List<String> urls;
    try {
      urls = await ref.read(chatRoomRemoteProvider).fetchBackgrounds();
    } catch (e) {
      _snack(ApiException.userMessage(e));
      return;
    }
    if (!mounted) return;
    if (urls.isEmpty) {
      _snack('Hazır arka plan bulunamadı');
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.6,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.6,
            ),
            itemCount: urls.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.pop(ctx, urls[i]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CanlifalNetworkImage(url: urls[i], fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
    );
    if (picked == null) return;
    await _run(
      () => ref.read(chatRoomRemoteProvider).setRoomBackground(
            roomKey: _key,
            backgroundImage: picked,
          ),
      'Arka plan güncellendi',
    );
  }

  Future<void> _setPassword() async {
    final v = await _textDialog(
      title: 'Giriş şifresi',
      hint: 'En az 4 karakter',
      maxLength: 32,
      obscure: true,
    );
    if (v == null) return;
    if (v.length < 4) {
      _snack('Şifre en az 4 karakter olmalı');
      return;
    }
    await _patch({'password': v}, 'Şifre koyuldu');
  }

  Future<void> _pickSeatCount(OwnerRoomSettings s) async {
    final current = s.seatCount ?? kDefaultVoiceSeatCount;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _card,
      builder: (ctx) => SafeArea(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            const SizedBox(width: double.infinity, height: 8),
            for (var n = kMinVoiceSeatCount; n <= kMaxVoiceSeatCount; n++)
              ChoiceChip(
                label: Text('$n'),
                selected: n == current,
                onSelected: (_) => Navigator.pop(ctx, n),
              ),
            const SizedBox(width: double.infinity, height: 16),
          ],
        ),
      ),
    );
    if (picked == null || picked == current) return;
    await _patch({'seatCount': picked}, 'Koltuk sayısı $picked');
  }

  Future<SearchUserEntity?> _pickUser(String title) async {
    return showModalBottomSheet<SearchUserEntity>(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      builder: (ctx) => _UserSearchSheet(title: title),
    );
  }

  Future<void> _addDj() async {
    final u = await _pickUser('DJ ekle');
    if (u == null) return;
    await _run(
      () => ref.read(chatRoomRemoteProvider).addRoomDj(
            roomKey: _key,
            targetUserId: u.id,
            targetLabel: u.name,
          ),
      '${u.name} DJ yapıldı',
    );
  }

  Future<void> _removeDj(String userId) => _run(
        () => ref.read(chatRoomRemoteProvider).removeRoomDj(
              roomKey: _key,
              targetUserId: userId,
            ),
        'DJ kaldırıldı',
      );

  Future<void> _addStaff() async {
    final u = await _pickUser('Yetkili ekle');
    if (u == null || !mounted) return;
    final role = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _card,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in const [
              ('@', 'Moderatör', 'Susturma, atma, mesaj silme'),
              ('&', 'Yönetici', 'Moderatör + koltuk ve oda yönetimi'),
              ('+', 'Konuşmacı', 'Mikrofon izni'),
            ])
              ListTile(
                title: Text(r.$2, style: const TextStyle(color: Colors.white)),
                subtitle: Text(r.$3, style: const TextStyle(color: _muted)),
                onTap: () => Navigator.pop(ctx, r.$1),
              ),
          ],
        ),
      ),
    );
    if (role == null) return;
    await _run(
      () => ref.read(chatRoomRemoteProvider).assignRole(
            roomKey: _key,
            userId: u.id,
            roleSymbol: role,
          ),
      '${u.name} yetkili yapıldı',
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ownerRoomSettingsProvider(_key));
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Oda yönetimi'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ApiException.userMessage(e),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(ownerRoomSettingsProvider(_key)),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: _body,
      ),
    );
  }

  Widget _body(OwnerRoomSettings s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _header(s),
        _section('Oda bilgileri'),
        _tile(Icons.edit_rounded, 'Oda adı', s.name, () => _editName(s)),
        _tile(
          Icons.notes_rounded,
          'Açıklama',
          s.description.isEmpty ? 'Ekle' : s.description,
          () => _editDescription(s),
        ),
        _tile(
          Icons.category_rounded,
          'Kategori',
          voiceRoomCategoryLabel(s.category),
          () => _pickCategory(s),
        ),
        _section('Görünüm ve giriş'),
        _tile(Icons.wallpaper_rounded, 'Arka plan resmi', 'Değiştir', _pickBackground),
        _tile(
          s.hasPassword ? Icons.lock_rounded : Icons.lock_open_rounded,
          'Giriş şifresi',
          s.hasPassword ? 'Şifre var — değiştir' : 'Şifre yok — koy',
          _setPassword,
        ),
        if (s.hasPassword)
          _tile(
            Icons.no_encryption_rounded,
            'Şifreyi kaldır',
            'Herkes girebilsin',
            () => _patch({'password': null}, 'Şifre kaldırıldı'),
          ),
        _tile(
          Icons.event_seat_rounded,
          'Koltuk sayısı',
          '${s.seatCount ?? kDefaultVoiceSeatCount} koltuk (en fazla $kMaxVoiceSeatCount)',
          () => _pickSeatCount(s),
        ),
        _switch(
          Icons.volume_off_rounded,
          'Odayı sessize al',
          s.isMuted,
          (v) => _patch({'isMuted': v}, v ? 'Oda sessize alındı' : 'Oda sesi açıldı'),
        ),
        _section('Mesajlar'),
        _tile(
          Icons.waving_hand_rounded,
          'Karşılama mesajı',
          s.welcomeMessage ?? 'Ekle',
          () async {
            final v = await _textDialog(
              title: 'Karşılama mesajı',
              initial: s.welcomeMessage ?? '',
              maxLines: 3,
              maxLength: 200,
            );
            if (v != null) await _patch({'welcomeMessage': v}, 'Kaydedildi');
          },
        ),
        _tile(
          Icons.push_pin_rounded,
          'Sabit duyuru',
          s.pinnedAnnouncement ?? 'Ekle',
          () async {
            final v = await _textDialog(
              title: 'Sabit duyuru',
              initial: s.pinnedAnnouncement ?? '',
              maxLines: 3,
              maxLength: 200,
            );
            if (v != null) await _patch({'pinnedAnnouncement': v}, 'Kaydedildi');
          },
        ),
        _section('Ekip'),
        for (final id in s.djUserIds) _DjRow(userId: id, onRemove: () => _removeDj(id)),
        _tile(Icons.headphones_rounded, 'DJ ekle', 'En fazla 5 DJ', _addDj),
        _tile(
          Icons.admin_panel_settings_rounded,
          'Yetkili ekle',
          'Moderatör, yönetici veya konuşmacı',
          _addStaff,
        ),
        _section('Gelir'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, color: _muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hediye komisyon oranı: %${s.commissionPercent}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Bu oranı yalnızca CanlıFal yönetimi değiştirebilir.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => openVoiceRoomWithVipGate(
            context,
            ref,
            widget.room,
            skipVipGateForOwner: true,
          ),
          icon: const Icon(Icons.login_rounded),
          label: const Text('Odaya gir'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }

  Widget _header(OwnerRoomSettings s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name.isEmpty ? widget.room.displayTitle : s.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    VoiceRoomCategoryChip(category: s.category),
                    _pill('${widget.room.displayOnline} çevrimiçi'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
        child: Text(
          title,
          style: const TextStyle(
            color: _accent,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _tile(IconData icon, String title, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          enabled: !_busy,
          leading: Icon(icon, color: _accent),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _switch(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        child: SwitchListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          secondary: Icon(icon, color: _accent),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          value: value,
          onChanged: _busy ? null : onChanged,
        ),
      ),
    );
  }
}

/// Kategori rozeti — "Odalarım" listesinde ve yönetim sayfasında.
class VoiceRoomCategoryChip extends StatelessWidget {
  const VoiceRoomCategoryChip({super.key, required this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final label = voiceRoomCategoryLabel(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC928).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC928).withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFE08A),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DjRow extends ConsumerWidget {
  const _DjRow({required this.userId, required this.onRemove});

  final String userId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider(userId)).valueOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF1B1430),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: UserAvatar(url: user?.avatarUrl, radius: 18),
          title: Text(
            user?.display ?? 'DJ',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          subtitle: const Text('DJ', style: TextStyle(color: Color(0xFFC9C3DA))),
          trailing: IconButton(
            tooltip: 'DJ yetkisini kaldır',
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFFF6B81)),
            onPressed: onRemove,
          ),
        ),
      ),
    );
  }
}

class _UserSearchSheet extends ConsumerStatefulWidget {
  const _UserSearchSheet({required this.title});

  final String title;

  @override
  ConsumerState<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends ConsumerState<_UserSearchSheet> {
  final _ctrl = TextEditingController();
  List<SearchUserEntity> _results = const [];
  var _loading = false;
  var _seq = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    final seq = ++_seq;
    if (query.length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await ref.read(searchRemoteProvider).searchUsers(query);
      if (!mounted || seq != _seq) return;
      setState(() => _results = list);
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _results = const []);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Kullanıcı adı ara',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: _search,
                ),
              ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final u = _results[i];
                    return ListTile(
                      leading: UserAvatar(url: u.image, radius: 18),
                      title: Text(u.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '@${u.username}',
                        style: const TextStyle(color: Color(0xFFC9C3DA)),
                      ),
                      onTap: () => Navigator.pop(context, u),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
