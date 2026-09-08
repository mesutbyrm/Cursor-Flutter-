import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/admin_site_animation.dart';
import '../providers/admin_site_animation_providers.dart';
import '../../../../core/site_animation/presentation/site_animation_catalog_provider.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_user_picker.dart';

/// Animasyonları etkinlik / günlük ödül olarak toplu ata.
class AdminSiteAnimationsRewardPage extends ConsumerStatefulWidget {
  const AdminSiteAnimationsRewardPage({super.key});

  @override
  ConsumerState<AdminSiteAnimationsRewardPage> createState() =>
      _AdminSiteAnimationsRewardPageState();
}

class _AdminSiteAnimationsRewardPageState
    extends ConsumerState<AdminSiteAnimationsRewardPage> {
  AdminSiteAnimationMembership _membership =
      AdminSiteAnimationMembership.gold;
  AdminSiteAnimationSlot _slot = AdminSiteAnimationSlot.entrance;
  AdminSiteAnimationDurationPreset _duration =
      AdminSiteAnimationDurationPreset.days30;
  String? _animationId;
  var _busy = false;

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

  Future<void> _assignToUser() async {
    final user = await AdminUserPicker.show(context, ref);
    if (user == null || !mounted) return;
    final uid = user['id']?.toString() ?? user['userId']?.toString();
    if (uid == null || uid.isEmpty) return;
    if (_animationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animasyon seçin')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminSiteAnimationRemoteProvider).assignAnimation(
            userId: uid,
            slot: _slot,
            animationId: _animationId,
            expiresAt: _expiresAt(),
          );
      ref.invalidate(siteAnimationCatalogProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödül atandı — ${user['name'] ?? uid}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageSiteAnimations) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ödül Animasyonu')),
        body: const Center(child: Text('Yetkisiz')),
      );
    }

    final animations = (ref.watch(adminSiteAnimationListProvider).valueOrNull ??
            const <AdminSiteAnimation>[])
        .where((a) => a.isActive)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('Ödül Animasyonu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Animasyonları etkinlik, günlük giriş veya kampanya ödülü olarak verin. '
            'Süre dolunca otomatik kapanır.',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _animationId,
            decoration: const InputDecoration(labelText: 'Ödül animasyonu'),
            items: animations
                .map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} (${a.category.label})'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _animationId = v),
          ),
          DropdownButtonFormField<AdminSiteAnimationSlot>(
            value: _slot,
            decoration: const InputDecoration(labelText: 'Slot'),
            items: AdminSiteAnimationSlot.values
                .map(
                  (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                )
                .toList(),
            onChanged: (v) => setState(() => _slot = v!),
          ),
          DropdownButtonFormField<AdminSiteAnimationDurationPreset>(
            value: _duration,
            decoration: const InputDecoration(labelText: 'Süre'),
            items: AdminSiteAnimationDurationPreset.values
                .where((p) => p != AdminSiteAnimationDurationPreset.custom)
                .map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                )
                .toList(),
            onChanged: (v) => setState(() => _duration = v!),
          ),
          DropdownButtonFormField<AdminSiteAnimationMembership>(
            value: _membership,
            decoration: const InputDecoration(labelText: 'Hedef üyelik (toplu)'),
            items: AdminSiteAnimationMembership.values
                .where((m) => m != AdminSiteAnimationMembership.all)
                .map(
                  (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                )
                .toList(),
            onChanged: (v) => setState(() => _membership = v!),
          ),
          const SizedBox(height: 20),
          if (_busy) const LinearProgressIndicator(),
          FilledButton.icon(
            onPressed: _busy ? null : _assignToUser,
            icon: const Icon(Icons.card_giftcard_outlined),
            label: const Text('Kullanıcıya ödül ver'),
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.accentPurple,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => context.push('/admin/site-animations/bulk-assign'),
            icon: const Icon(Icons.groups_outlined),
            label: const Text('Toplu atama sayfası'),
          ),
        ],
      ),
    );
  }
}
