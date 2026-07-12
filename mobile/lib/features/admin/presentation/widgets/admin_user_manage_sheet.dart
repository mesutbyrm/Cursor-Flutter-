import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/admin_user_util.dart';
import '../pages/admin_panel_page.dart';
import '../providers/admin_panel_providers.dart';
import 'admin_credit_sheet.dart';
import 'admin_membership_sheet.dart';

class AdminUserManageSheet {
  AdminUserManageSheet._();

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required Map<String, dynamic> user,
  }) async {
    final userId = resolveAdminUserId(user);
    if (userId.isEmpty) return;

    Map<String, dynamic> detail = normalizeAdminUserMap(user);
    try {
      detail = await ref.read(adminRemoteProvider).fetchUser(userId);
    } catch (_) {}

    final nameCtrl = TextEditingController(
      text: (detail['displayName'] ?? detail['name'] ?? '').toString(),
    );
    final bioCtrl = TextEditingController(
      text: (detail['bio'] ?? '').toString(),
    );
    final emailCtrl = TextEditingController(
      text: (detail['email'] ?? '').toString(),
    );
    var role = (detail['role'] ?? 'user').toString();
    var membership = (detail['membership'] ?? 'basic').toString();

    final label = user['username']?.toString().trim().isNotEmpty == true
        ? '@${user['username']}'
        : userId;

    final jeton = detail['coins'] ??
        detail['jetonBalance'] ??
        detail['jeton'] ??
        user['coins'] ??
        user['jetonBalance'] ??
        '—';
    final cfc = detail['cfcBalance'] ??
        detail['cfc'] ??
        user['cfcBalance'] ??
        user['cfc'] ??
        '—';

    if (!context.mounted) return;

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
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Kullanıcı yönetimi',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 12),
                  _BalanceRow(jeton: jeton.toString(), cfc: cfc.toString()),
                  const SizedBox(height: 12),
                  const Text(
                    'Hızlı işlemler',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickChip(
                        icon: Icons.monetization_on_outlined,
                        label: 'Jeton',
                        onTap: () async {
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          await AdminCreditSheet.show(
                            context,
                            ref: ref,
                            user: detail,
                            kind: AdminCreditKind.jeton,
                          );
                        },
                      ),
                      _QuickChip(
                        icon: Icons.toll_outlined,
                        label: 'CFC',
                        onTap: () async {
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          await AdminCreditSheet.show(
                            context,
                            ref: ref,
                            user: detail,
                            kind: AdminCreditKind.cfc,
                          );
                        },
                      ),
                      _QuickChip(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Gold üyelik',
                        onTap: () async {
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          await AdminMembershipSheet.show(
                            context,
                            ref: ref,
                            user: detail,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Görünen ad',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bioCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Yetki / rol',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Kullanıcı')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'yonetici',
                        child: Text('Kurucu (yonetici)'),
                      ),
                      DropdownMenuItem(
                        value: 'moderator',
                        child: Text('Moderatör'),
                      ),
                      DropdownMenuItem(value: 'destek', child: Text('Destek')),
                      DropdownMenuItem(value: 'yardim', child: Text('Yardım')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => role = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: membership,
                    decoration: const InputDecoration(
                      labelText: 'Üyelik seviyesi',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'basic', child: Text('Basic')),
                      DropdownMenuItem(value: 'gold', child: Text('Gold')),
                      DropdownMenuItem(
                        value: 'premium',
                        child: Text('Premium'),
                      ),
                      DropdownMenuItem(
                        value: 'diamond',
                        child: Text('Diamond'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => membership = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await ref.read(adminRemoteProvider).updateUser(
                              userId,
                              {
                                'displayName': nameCtrl.text.trim(),
                                'name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'bio': bioCtrl.text.trim(),
                                'role': role,
                                'membership': membership,
                              },
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kullanıcı güncellendi')),
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
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    bioCtrl.dispose();
    emailCtrl.dispose();
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.jeton, required this.cfc});

  final String jeton;
  final String cfc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BalanceTile(
            icon: Icons.monetization_on_outlined,
            label: 'Jeton',
            value: jeton,
            color: AppThemeColors.coinGold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BalanceTile(
            icon: Icons.toll_outlined,
            label: 'CFC',
            value: cfc,
            color: AppThemeColors.accentCyan,
          ),
        ),
      ],
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppThemeColors.accentPurple),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
