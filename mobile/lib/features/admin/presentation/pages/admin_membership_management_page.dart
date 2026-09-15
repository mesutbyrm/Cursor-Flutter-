import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/me/me_entitlements_providers.dart';
import '../../../../core/membership/membership_capability_keys.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../providers/staff_access_provider.dart';

/// Admin — üyelik kademeleri ve capability matrisi (canlifal.com API).
class AdminMembershipManagementPage extends ConsumerStatefulWidget {
  const AdminMembershipManagementPage({super.key});

  @override
  ConsumerState<AdminMembershipManagementPage> createState() =>
      _AdminMembershipManagementPageState();
}

class _AdminMembershipManagementPageState
    extends ConsumerState<AdminMembershipManagementPage> {
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tiers = [];
  List<Map<String, dynamic>> _features = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final dio = ref.read(dioProvider);
    try {
      final tiersRes = await dio.safeGet<dynamic>(ApiEndpoints.adminMembershipTiers);
      final featRes =
          await dio.safeGet<dynamic>(ApiEndpoints.adminMembershipFeatures);
      _tiers = _parseList(tiersRes.data);
      _features = _parseList(featRes.data);
    } catch (e) {
      _error = ApiException.userMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _cellEnabled(String tierKey, String featureKey) {
    for (final f in _features) {
      final fk = (f['key'] ?? f['featureKey'] ?? '').toString();
      if (fk != featureKey) continue;
      final cells = f['cells'] ?? f['tierGrants'] ?? f['grants'];
      if (cells is Map) {
        final v = cells[tierKey];
        if (v is bool) return v;
        if (v is Map) return v['enabled'] == true;
      }
      if (cells is List) {
        for (final c in cells) {
          if (c is! Map) continue;
          final tk = (c['tierKey'] ?? c['tier'] ?? '').toString();
          if (tk == tierKey) return c['enabled'] == true;
        }
      }
    }
    return false;
  }

  Future<void> _setFeatureCell(
    String tierKey,
    String featureKey,
    bool enabled,
  ) async {
    if (tierKey.isEmpty || featureKey.isEmpty) return;
    final dio = ref.read(dioProvider);
    try {
      await dio.safePut<dynamic>(
        ApiEndpoints.adminMembershipFeatures,
        query: {'tierKey': tierKey, 'featureKey': featureKey},
        data: {
          'cells': [
            {
              'tierKey': tierKey,
              'featureKey': featureKey,
              'enabled': enabled,
            },
          ],
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$tierKey · $featureKey → $enabled')),
        );
      }
      await _load();
      ref.invalidate(meMembershipPackageProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  Future<void> _setTierActive(String key, bool active) async {
    if (key.isEmpty) return;
    final dio = ref.read(dioProvider);
    try {
      await dio.safePut<dynamic>(
        ApiEndpoints.adminMembershipTiers,
        query: {'key': key},
        data: {'isActive': active},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(active ? '$key aktif' : '$key pasif')),
        );
      }
      await _load();
      ref.invalidate(meMembershipPackageProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) {
      return data.map((e) => asJsonMap(e)).toList();
    }
    if (data is Map) {
      final items = data['items'] ?? data['tiers'] ?? data['features'];
      if (items is List) {
        return items.map((e) => asJsonMap(e)).toList();
      }
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(staffAccessProvider);
    if (!staff.canManagePayments && !staff.isSiteAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Üyelik Yönetimi')),
        body: const Center(child: Text('Yetkiniz yok.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Üyelik Yönetimi'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Yeniden dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Kademeler ve özellikler sunucudan yüklenir. '
                        'Değişiklikler APK gerektirmez.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kademeler (${_tiers.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_tiers.isEmpty)
                        const Text('API boş — üretimde seed gerekir.')
                      else
                        ..._tiers.map(_tierTile),
                      if (_tiers.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Tier × özellik matrisi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...[
                          MembershipCapabilityKeys.adFree,
                          MembershipCapabilityKeys.profileFrame,
                          MembershipCapabilityKeys.entranceEffect,
                          MembershipCapabilityKeys.hiddenOnline,
                          MembershipCapabilityKeys.hiddenRoomEntry,
                          MembershipCapabilityKeys.profileVisitors,
                          MembershipCapabilityKeys.vipRooms,
                          MembershipCapabilityKeys.svipLounge,
                        ].map(
                          (featureKey) => ExpansionTile(
                            title: Text(featureKey, style: const TextStyle(fontSize: 13)),
                            children: [
                              for (final t in _tiers)
                                Builder(
                                  builder: (context) {
                                    final tierKey =
                                        (t['key'] ?? t['id'] ?? '').toString();
                                    if (tierKey.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    final on = _cellEnabled(tierKey, featureKey);
                                    return SwitchListTile(
                                      dense: true,
                                      title: Text(
                                        (t['name'] ?? tierKey).toString(),
                                      ),
                                      value: on,
                                      onChanged: (v) => _setFeatureCell(
                                        tierKey,
                                        featureKey,
                                        v,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Capability anahtarları (istemci)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...[
                              MembershipCapabilityKeys.profileFrame,
                              MembershipCapabilityKeys.entranceEffect,
                              MembershipCapabilityKeys.hiddenOnline,
                              MembershipCapabilityKeys.profileVisitors,
                              MembershipCapabilityKeys.vipRooms,
                              MembershipCapabilityKeys.svipLounge,
                              MembershipCapabilityKeys.discoveryPriority,
                            ].map(
                              (k) => ListTile(
                                dense: true,
                                title: Text(k),
                                subtitle: Text(
                                  _features
                                          .any((f) => f['key'] == k)
                                      ? 'Sunucu kataloğunda'
                                      : 'Yalnızca istemci fallback',
                                ),
                              ),
                            ),
                      if (_features.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Sunucu özellikleri (${_features.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        ..._features.take(40).map(
                              (f) => ListTile(
                                title: Text(
                                  (f['name'] ?? f['key'] ?? '—').toString(),
                                ),
                                subtitle: Text(
                                  '${f['key'] ?? ''} · ${f['category'] ?? ''}',
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _tierTile(Map<String, dynamic> t) {
    final key = (t['key'] ?? t['id'] ?? '').toString();
    final name = (t['name'] ?? key).toString();
    final weight = t['discoveryWeight'] ?? t['discovery_weight'];
    final isActive = t['isActive'] != false;
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(
          'key: $key'
          '${weight != null ? ' · keşfet ağırlığı: $weight' : ''}',
        ),
        trailing: Switch(
          value: isActive,
          onChanged: key.isEmpty ? null : (v) => _setTierActive(key, v),
        ),
      ),
    );
  }
}
