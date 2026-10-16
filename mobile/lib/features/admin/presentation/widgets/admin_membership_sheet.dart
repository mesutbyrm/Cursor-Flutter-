import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/admin_user_util.dart';
import '../providers/admin_panel_providers.dart';

class AdminMembershipSheet {
  AdminMembershipSheet._();

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required Map<String, dynamic> user,
  }) async {
    final normalized = normalizeAdminUserMap(user);
    final noteCtrl = TextEditingController();
    var tier = 'gold';
    var duration = 'monthly';
    var busy = false;

    final userId = resolveAdminUserId(normalized);
    final label = normalized['username']?.toString().trim().isNotEmpty == true
        ? '@${normalized['username']}'
        : (normalized['displayName'] ?? normalized['name'] ?? userId).toString();
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> apply() async {
              if (busy) return;
              if (userId.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Kullanıcı kimliği bulunamadı — aramadan tekrar seçin.',
                    ),
                  ),
                );
                return;
              }

              setState(() => busy = true);
              HapticFeedback.mediumImpact();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${_tierLabel(tier)} üyelik veriliyor…'),
                  duration: const Duration(seconds: 2),
                ),
              );

              try {
                await ref.read(adminRemoteProvider).grantMembership(
                      userId: userId,
                      tier: tier,
                      duration: duration,
                      reason: noteCtrl.text.trim(),
                    );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '${_tierLabel(tier)} üyelik verildi '
                      '(${_durationLabel(duration)})',
                    ),
                    backgroundColor: Colors.green.shade800,
                  ),
                );
              } catch (e) {
                if (ctx.mounted) {
                  setState(() => busy = false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(ApiException.userMessage(e)),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Üyelik ver',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t in ['gold', 'premium', 'diamond'])
                        ChoiceChip(
                          label: Text(_tierLabel(t)),
                          selected: tier == t,
                          onSelected: busy ? null : (_) => setState(() => tier = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final d in ['daily', 'weekly', 'monthly'])
                        ChoiceChip(
                          label: Text(_durationLabel(d)),
                          selected: duration == d,
                          onSelected:
                              busy ? null : (_) => setState(() => duration = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    enabled: !busy,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeColors.accentCyan,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Üyelik ver'),
                  ),
                  const SizedBox(height: 8),
                  // Üyeliği temel (ücretsiz) seviyeye düşür — sunucuda
                  // `gold_revoke` (yetki + denetim kaydı).
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            final ok = await showDialog<bool>(
                              context: ctx,
                              builder: (d) => AlertDialog(
                                title: const Text('Üyeliği kaldır'),
                                content: Text(
                                  '$label kullanıcısının üyeliği temel seviyeye düşürülecek. Emin misiniz?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(d, false),
                                    child: const Text('Vazgeç'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(d, true),
                                    child: const Text('Kaldır'),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true || !ctx.mounted) return;
                            setState(() => busy = true);
                            try {
                              await ref.read(adminRemoteProvider).manageUser(
                                userId,
                                'gold_revoke',
                                {
                                  if (noteCtrl.text.trim().isNotEmpty)
                                    'reason': noteCtrl.text.trim(),
                                },
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Üyelik temel seviyeye düşürüldü'),
                                ),
                              );
                            } catch (e) {
                              if (ctx.mounted) setState(() => busy = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(ApiException.userMessage(e)),
                                  backgroundColor: Colors.red.shade800,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    label: const Text('Üyeliği kaldır (temel seviyeye düşür)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    noteCtrl.dispose();
  }

  static String _tierLabel(String t) => switch (t) {
        'gold' => 'Gold',
        'premium' => 'Premium',
        'diamond' => 'Diamond',
        _ => t,
      };

  static String _durationLabel(String d) => switch (d) {
        'daily' => 'Günlük',
        'weekly' => 'Haftalık',
        'monthly' => 'Aylık',
        _ => d,
      };
}
