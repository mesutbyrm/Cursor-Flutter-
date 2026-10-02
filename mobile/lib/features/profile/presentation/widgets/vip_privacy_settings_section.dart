import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/me/vip_preferences_model.dart';
import '../../../../core/me/vip_preferences_providers.dart';
import '../../../../core/membership/membership_capability_gate.dart';
import '../../../../core/membership/membership_capability_keys.dart';
import '../../../../core/membership/membership_capability_providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/settings_kit.dart';
import 'premium/profile_glass.dart';

/// Ayarlar — VIP gizlilik (`/api/me/vip-preferences`).
class VipPrivacySettingsSection extends ConsumerWidget {
  const VipPrivacySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(membershipCapabilitiesSyncProvider);
    final prefsAsync = ref.watch(vipPreferencesProvider);

    return prefsAsync.when(
      loading: () => const ProfileGlass(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => ProfileGlass(
        child: ListTile(
          title: const Text('VIP gizlilik yüklenemedi'),
          subtitle: Text(ApiException.userMessage(e)),
          trailing: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(vipPreferencesProvider),
          ),
        ),
      ),
      data: (prefs) {
        final rejected = prefs.rejected;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rejected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Sunucu reddetti: ${rejected.join(', ')}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            SettingsTileGrid(
              children: [
                _VipPrefSwitch(
                  icon: Icons.visibility_off_rounded,
                  label: 'Çevrimiçi durumumu gizle',
                  subtitle: 'Premium+',
                  capabilityKey: MembershipCapabilityKeys.hiddenOnline,
                  value: prefs.hideOnlineStatus,
                  enabled: caps.allows(MembershipCapabilityKeys.hiddenOnline),
                  lockedMessage:
                      'Çevrimiçi gizleme için Premium veya üzeri gerekir.',
                  onChanged: (v) =>
                      _save(ref, prefs.copyWith(hideOnlineStatus: v)),
                ),
                _VipPrefSwitch(
                  icon: Icons.meeting_room_rounded,
                  label: 'Odaya gizli giriş',
                  subtitle: 'Premium+',
                  capabilityKey: MembershipCapabilityKeys.hiddenRoomEntry,
                  value: prefs.hiddenRoomEntry,
                  enabled:
                      caps.allows(MembershipCapabilityKeys.hiddenRoomEntry),
                  lockedMessage:
                      'Gizli oda girişi için Premium veya üzeri gerekir.',
                  onChanged: (v) =>
                      _save(ref, prefs.copyWith(hiddenRoomEntry: v)),
                ),
                _VipPrefSwitch(
                  icon: Icons.workspace_premium_rounded,
                  label: 'VIP rozetini gizle',
                  capabilityKey: MembershipCapabilityKeys.hideVipBadge,
                  value: prefs.hideVipBadge,
                  enabled: caps.allows(MembershipCapabilityKeys.hideVipBadge),
                  lockedMessage: 'Rozet gizleme Premium+ özelliğidir.',
                  onChanged: (v) =>
                      _save(ref, prefs.copyWith(hideVipBadge: v)),
                ),
                _VipPrefSwitch(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Giriş efektlerini kapat',
                  capabilityKey: MembershipCapabilityKeys.entranceEffect,
                  value: prefs.disableEntranceEffects,
                  enabled: caps.allows(MembershipCapabilityKeys.entranceEffect),
                  lockedMessage: 'Gold+ giriş efekti gerekir.',
                  onChanged: (v) =>
                      _save(ref, prefs.copyWith(disableEntranceEffects: v)),
                ),
                _VipPrefSwitch(
                  icon: Icons.volume_off_rounded,
                  label: 'Başkalarının giriş efektini sessize al',
                  value: prefs.muteOthersEntrance,
                  enabled: true,
                  onChanged: (v) =>
                      _save(ref, prefs.copyWith(muteOthersEntrance: v)),
                ),
              ],
            ),
            if (caps.allows(MembershipCapabilityKeys.svipLounge)) ...[
              const SizedBox(height: 12),
              SettingsTileGrid(
                children: [
                  SettingsTileCard(
                    icon: Icons.weekend_rounded,
                    label: 'SVIP Lounge',
                    subtitle: 'Özel SVIP sesli odalar',
                    accent: const Color(0xFFFFC107),
                    onTap: () => context.push('/vip-svip-lounge'),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _save(WidgetRef ref, VipPreferences next) async {
    try {
      await ref.read(vipPreferencesProvider.notifier).savePrefs(next);
    } catch (e) {
      // Snackbar üst widget'ta gösterilmez; invalidate ile yenile
      ref.invalidate(vipPreferencesProvider);
    }
  }
}

class _VipPrefSwitch extends StatelessWidget {
  const _VipPrefSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.subtitle,
    this.lockedMessage,
    this.capabilityKey = MembershipCapabilityKeys.hiddenOnline,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final String capabilityKey;
  final bool value;
  final bool enabled;
  final String? lockedMessage;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!enabled && lockedMessage != null) {
      return SettingsTileCard(
        icon: Icons.lock_outline_rounded,
        label: label,
        subtitle: lockedMessage,
        accent: Theme.of(context).disabledColor,
        badge: 'Kilitli',
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(label),
              content: MembershipCapabilityLockedBody(
                capabilityKey: capabilityKey,
                title: label,
                message: lockedMessage!,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat'),
                ),
              ],
            ),
          );
        },
      );
    }

    return SettingsToggleTile(
      icon: icon,
      label: label,
      subtitle: subtitle,
      value: enabled ? value : false,
      onChanged: (v) {
        if (enabled) onChanged(v);
      },
    );
  }
}
