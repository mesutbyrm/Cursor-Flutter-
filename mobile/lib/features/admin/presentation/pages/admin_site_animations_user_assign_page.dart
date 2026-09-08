import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/admin_site_animation.dart';
import '../providers/admin_site_animation_providers.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_user_picker.dart';

class AdminSiteAnimationsUserAssignPage extends ConsumerStatefulWidget {
  const AdminSiteAnimationsUserAssignPage({super.key, this.preselectedAnimation});

  final AdminSiteAnimation? preselectedAnimation;

  @override
  ConsumerState<AdminSiteAnimationsUserAssignPage> createState() =>
      _AdminSiteAnimationsUserAssignPageState();
}

class _AdminSiteAnimationsUserAssignPageState
    extends ConsumerState<AdminSiteAnimationsUserAssignPage> {
  Map<String, dynamic>? _user;
  Map<AdminSiteAnimationSlot, String?> _assignments = {};
  AdminSiteAnimationDurationPreset _durationPreset =
      AdminSiteAnimationDurationPreset.unlimited;
  var _loading = false;

  Future<void> _pickUser() async {
    final user = await AdminUserPicker.show(context, ref);
    if (user == null || !mounted) return;
    setState(() {
      _user = user;
      _loading = true;
    });
    try {
      final uid = user['id']?.toString() ?? user['userId']?.toString() ?? '';
      final remote = ref.read(adminSiteAnimationRemoteProvider);
      final map = await remote.fetchUserAssignments(uid);
      if (mounted) setState(() => _assignments = map);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _assignSlot(AdminSiteAnimationSlot slot) async {
    final uid = _user?['id']?.toString() ?? _user?['userId']?.toString();
    if (uid == null || uid.isEmpty) return;

    final animations = ref.read(adminSiteAnimationListProvider).valueOrNull ?? [];
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Kaldır'),
              onTap: () => Navigator.pop(ctx, null),
            ),
            ...animations.where((a) => a.isActive).map(
                  (a) => ListTile(
                    title: Text(a.name),
                    subtitle: Text(a.category.label),
                    onTap: () => Navigator.pop(ctx, a.id),
                  ),
                ),
          ],
        ),
      ),
    );
    if (!mounted) return;

    final expires = _expiresAt();
    await ref.read(adminSiteAnimationRemoteProvider).assignAnimation(
          userId: uid,
          slot: slot,
          animationId: selected,
          expiresAt: expires,
        );
    setState(() => _assignments[slot] = selected);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(selected == null ? 'Kaldırıldı' : 'Atandı')),
      );
    }
  }

  DateTime? _expiresAt() {
    final now = DateTime.now();
    return switch (_durationPreset) {
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
        appBar: AppBar(title: const Text('Kullanıcıya Özel')),
        body: const Center(child: Text('Yetkisiz')),
      );
    }

    final name = _user?['name']?.toString() ??
        _user?['displayName']?.toString() ??
        'Kullanıcı seç';

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('Kullanıcıya Özel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            tileColor: const Color(0xFF12082A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(name),
            subtitle: const Text('Kullanıcı ara ve seç'),
            trailing: const Icon(Icons.search),
            onTap: _pickUser,
          ),
          if (widget.preselectedAnimation != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Seçili: ${widget.preselectedAnimation!.name}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          DropdownButtonFormField<AdminSiteAnimationDurationPreset>(
            value: _durationPreset,
            decoration: const InputDecoration(labelText: 'Süre'),
            items: AdminSiteAnimationDurationPreset.values
                .map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                )
                .toList(),
            onChanged: (v) => setState(() => _durationPreset = v!),
          ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          for (final slot in AdminSiteAnimationSlot.values)
            Card(
              color: const Color(0xFF12082A),
              child: ListTile(
                title: Text(slot.label),
                subtitle: Text(_assignments[slot] ?? '—'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: _user == null ? null : () => _assignSlot(slot),
                      child: const Text('Ata'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
