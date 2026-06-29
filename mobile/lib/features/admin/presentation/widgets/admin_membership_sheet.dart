import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../providers/admin_panel_providers.dart';

class AdminMembershipSheet {
  AdminMembershipSheet._();

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required Map<String, dynamic> user,
  }) async {
    final noteCtrl = TextEditingController();
    var tier = 'gold';
    var duration = 'monthly';

    final userId = user['id']?.toString() ?? '';
    final label = user['username']?.toString().trim().isNotEmpty == true
        ? '@${user['username']}'
        : (user['displayName'] ?? user['name'] ?? userId).toString();

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
                          onSelected: (_) => setState(() => tier = t),
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
                          onSelected: (_) => setState(() => duration = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (userId.isEmpty) return;
                      try {
                        await ref.read(adminRemoteProvider).grantMembership(
                              userId: userId,
                              tier: tier,
                              duration: duration,
                              reason: noteCtrl.text.trim(),
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${_tierLabel(tier)} üyelik verildi '
                                '(${_durationLabel(duration)})',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(ApiException.userMessage(e)),
                            ),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeColors.accentCyan,
                    ),
                    child: const Text('Üyelik ver'),
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
