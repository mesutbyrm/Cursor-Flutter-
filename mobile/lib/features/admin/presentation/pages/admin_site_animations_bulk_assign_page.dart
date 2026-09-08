import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/admin_site_animation.dart';
import '../providers/admin_site_animation_providers.dart';
import '../providers/staff_access_provider.dart';

enum AdminBulkAssignTarget {
  singleUser,
  multiUser,
  goldMembers,
  premiumMembers,
  diamondMembers,
  vipMembers,
  specificRoom,
  specificEvent,
}

class AdminSiteAnimationsBulkAssignPage extends ConsumerStatefulWidget {
  const AdminSiteAnimationsBulkAssignPage({super.key});

  @override
  ConsumerState<AdminSiteAnimationsBulkAssignPage> createState() =>
      _AdminSiteAnimationsBulkAssignPageState();
}

class _AdminSiteAnimationsBulkAssignPageState
    extends ConsumerState<AdminSiteAnimationsBulkAssignPage> {
  AdminBulkAssignTarget _target = AdminBulkAssignTarget.goldMembers;
  AdminSiteAnimationSlot _slot = AdminSiteAnimationSlot.entrance;
  String? _animationId;
  AdminSiteAnimationDurationPreset _duration =
      AdminSiteAnimationDurationPreset.days7;
  final _userIdsCtrl = TextEditingController();
  final _roomIdCtrl = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _userIdsCtrl.dispose();
    _roomIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_animationId == null) return;
    setState(() => _saving = true);
    try {
      final remote = ref.read(adminSiteAnimationRemoteProvider);
      final expires = _expiresAt();
      final userIds = _resolveUserIds();
      if (userIds.isEmpty) {
        throw const ApiException('Hedef kullanıcı bulunamadı.');
      }
      await remote.bulkAssign(
        userIds: userIds,
        slot: _slot,
        animationId: _animationId!,
        expiresAt: expires,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${userIds.length} kullanıcıya atandı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _resolveUserIds() {
    return switch (_target) {
      AdminBulkAssignTarget.multiUser => _userIdsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      AdminBulkAssignTarget.singleUser =>
        _userIdsCtrl.text.trim().isEmpty ? [] : [_userIdsCtrl.text.trim()],
      _ => ['bulk:${_target.name}'],
    };
  }

  DateTime? _expiresAt() {
    final now = DateTime.now();
    return switch (_duration) {
      AdminSiteAnimationDurationPreset.days1 => now.add(const Duration(days: 1)),
      AdminSiteAnimationDurationPreset.days7 => now.add(const Duration(days: 7)),
      AdminSiteAnimationDurationPreset.days30 =>
        now.add(const Duration(days: 30)),
      AdminSiteAnimationDurationPreset.days90 =>
        now.add(const Duration(days: 90)),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageSiteAnimations) {
      return Scaffold(
        appBar: AppBar(title: const Text('Toplu Atama')),
        body: const Center(child: Text('Yetkisiz')),
      );
    }

    final animations = ref.watch(adminSiteAnimationListProvider).valueOrNull ??
        const <AdminSiteAnimation>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('Toplu Atama'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<AdminBulkAssignTarget>(
            value: _target,
            decoration: const InputDecoration(labelText: 'Hedef'),
            items: AdminBulkAssignTarget.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(_targetLabel(t)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _target = v!),
          ),
          if (_target == AdminBulkAssignTarget.multiUser ||
              _target == AdminBulkAssignTarget.singleUser)
            TextField(
              controller: _userIdsCtrl,
              decoration: InputDecoration(
                labelText: _target == AdminBulkAssignTarget.singleUser
                    ? 'Kullanıcı ID'
                    : 'Kullanıcı ID listesi (virgülle)',
              ),
            ),
          if (_target == AdminBulkAssignTarget.specificRoom)
            TextField(
              controller: _roomIdCtrl,
              decoration: const InputDecoration(labelText: 'Oda ID'),
            ),
          DropdownButtonFormField<AdminSiteAnimationSlot>(
            value: _slot,
            decoration: const InputDecoration(labelText: 'Slot'),
            items: AdminSiteAnimationSlot.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) => setState(() => _slot = v!),
          ),
          DropdownButtonFormField<String?>(
            value: _animationId,
            decoration: const InputDecoration(labelText: 'Animasyon'),
            items: animations
                .where((a) => a.isActive)
                .map(
                  (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                )
                .toList(),
            onChanged: (v) => setState(() => _animationId = v),
          ),
          DropdownButtonFormField<AdminSiteAnimationDurationPreset>(
            value: _duration,
            decoration: const InputDecoration(labelText: 'Süre'),
            items: AdminSiteAnimationDurationPreset.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: (v) => setState(() => _duration = v!),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Toplu Ata'),
          ),
        ],
      ),
    );
  }

  String _targetLabel(AdminBulkAssignTarget t) => switch (t) {
        AdminBulkAssignTarget.singleUser => 'Tek kullanıcı',
        AdminBulkAssignTarget.multiUser => 'Çoklu kullanıcı',
        AdminBulkAssignTarget.goldMembers => 'Gold üyeler',
        AdminBulkAssignTarget.premiumMembers => 'Premium üyeler',
        AdminBulkAssignTarget.diamondMembers => 'Diamond üyeler',
        AdminBulkAssignTarget.vipMembers => 'VIP üyeler',
        AdminBulkAssignTarget.specificRoom => 'Belirli oda',
        AdminBulkAssignTarget.specificEvent => 'Belirli etkinlik',
      };
}
