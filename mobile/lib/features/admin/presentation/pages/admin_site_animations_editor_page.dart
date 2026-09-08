import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/admin_site_animation.dart';
import '../providers/admin_site_animation_providers.dart';
import '../providers/staff_access_provider.dart';

class AdminSiteAnimationsEditorPage extends ConsumerStatefulWidget {
  const AdminSiteAnimationsEditorPage({super.key, this.animation});

  final AdminSiteAnimation? animation;

  @override
  ConsumerState<AdminSiteAnimationsEditorPage> createState() =>
      _AdminSiteAnimationsEditorPageState();
}

class _AdminSiteAnimationsEditorPageState
    extends ConsumerState<AdminSiteAnimationsEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _duration;
  late final TextEditingController _priority;
  late final TextEditingController _scale;
  late final TextEditingController _cooldown;
  late final TextEditingController _assetUrl;
  late final TextEditingController _previewUrl;
  late final TextEditingController _soundUrl;
  late AdminSiteAnimationCategory _category;
  late AdminSiteAnimationMembership _membership;
  late AdminSiteAnimationAnchor _anchor;
  late AdminSiteAnimationRarity _rarity;
  late String _animationType;
  late String _context;
  var _isActive = true;
  var _saving = false;

  bool get _isEdit => widget.animation != null;

  @override
  void initState() {
    super.initState();
    final a = widget.animation;
    _name = TextEditingController(text: a?.name ?? '');
    _duration = TextEditingController(text: '${a?.durationMs ?? 3000}');
    _priority = TextEditingController(text: '${a?.priority ?? 50}');
    _scale = TextEditingController(text: '${a?.scale ?? 1}');
    _cooldown = TextEditingController(text: '${a?.cooldownMs ?? 0}');
    _assetUrl = TextEditingController(text: a?.assetUrl ?? '');
    _previewUrl = TextEditingController(text: a?.previewUrl ?? '');
    _soundUrl = TextEditingController(text: a?.soundUrl ?? '');
    _category = a?.category ?? AdminSiteAnimationCategory.entrance;
    _membership = a?.membership ?? AdminSiteAnimationMembership.normal;
    _anchor = a?.anchor ?? AdminSiteAnimationAnchor.topLeft;
    _rarity = a?.rarity ?? AdminSiteAnimationRarity.common;
    _animationType = a?.animationType ?? 'native';
    _context = a?.context ?? 'voice_room';
    _isActive = a?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _duration.dispose();
    _priority.dispose();
    _scale.dispose();
    _cooldown.dispose();
    _assetUrl.dispose();
    _previewUrl.dispose();
    _soundUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final item = AdminSiteAnimation(
        id: widget.animation?.id ??
            'anim_${DateTime.now().millisecondsSinceEpoch}',
        name: _name.text.trim(),
        category: _category,
        membership: _membership,
        animationType: _animationType,
        assetUrl: _assetUrl.text.trim().isEmpty ? null : _assetUrl.text.trim(),
        previewUrl:
            _previewUrl.text.trim().isEmpty ? null : _previewUrl.text.trim(),
        soundUrl: _soundUrl.text.trim().isEmpty ? null : _soundUrl.text.trim(),
        durationMs: int.tryParse(_duration.text) ?? 3000,
        priority: int.tryParse(_priority.text) ?? 50,
        rarity: _rarity,
        context: _context,
        anchor: _anchor,
        scale: double.tryParse(_scale.text) ?? 1,
        cooldownMs: int.tryParse(_cooldown.text) ?? 0,
        isActive: _isActive,
      );
      await ref.read(adminSiteAnimationListProvider.notifier).save(
            item,
            create: !_isEdit,
          );
      if (mounted) {
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Güncellendi' : 'Oluşturuldu')),
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

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageSiteAnimations) {
      return Scaffold(
        appBar: AppBar(title: const Text('Animasyon')),
        body: const Center(child: Text('Yetkisiz')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: Text(_isEdit ? 'Animasyon Düzenle' : 'Animasyon Ekle'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kaydet'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Animation Name'),
          ),
          const SizedBox(height: 12),
          _Dropdown<AdminSiteAnimationCategory>(
            label: 'Category',
            value: _category,
            items: AdminSiteAnimationCategory.values,
            labelOf: (v) => v.label,
            onChanged: (v) => setState(() => _category = v!),
          ),
          _Dropdown<AdminSiteAnimationMembership>(
            label: 'Membership',
            value: _membership,
            items: AdminSiteAnimationMembership.values
                .where((m) => m != AdminSiteAnimationMembership.all)
                .toList(),
            labelOf: (v) => v.label,
            onChanged: (v) => setState(() => _membership = v!),
          ),
          _Dropdown<String>(
            label: 'Animation Type',
            value: _animationType,
            items: const ['native', 'lottie', 'svga', 'video', 'rive'],
            labelOf: (v) => v,
            onChanged: (v) => setState(() => _animationType = v!),
          ),
          TextField(
            controller: _assetUrl,
            decoration: const InputDecoration(labelText: 'Upload Asset (URL)'),
          ),
          TextField(
            controller: _previewUrl,
            decoration: const InputDecoration(labelText: 'Upload Preview (URL)'),
          ),
          TextField(
            controller: _soundUrl,
            decoration: const InputDecoration(labelText: 'Upload Sound (URL)'),
          ),
          TextField(
            controller: _duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration (ms)'),
          ),
          TextField(
            controller: _priority,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Priority'),
          ),
          _Dropdown<AdminSiteAnimationRarity>(
            label: 'Rarity',
            value: _rarity,
            items: AdminSiteAnimationRarity.values,
            labelOf: (v) => v.name,
            onChanged: (v) => setState(() => _rarity = v!),
          ),
          TextField(
            controller: _scale,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Scale'),
          ),
          _Dropdown<AdminSiteAnimationAnchor>(
            label: 'Anchor',
            value: _anchor,
            items: AdminSiteAnimationAnchor.values,
            labelOf: (v) => v.wire,
            onChanged: (v) => setState(() => _anchor = v!),
          ),
          TextField(
            controller: _cooldown,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cooldown (ms)'),
          ),
          SwitchListTile(
            title: const Text('Aktif'),
            subtitle: const Text('Pasif animasyon Flutter\'a gönderilmez'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(labelOf(e))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
