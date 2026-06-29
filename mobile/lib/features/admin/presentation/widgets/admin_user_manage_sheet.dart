import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../providers/admin_panel_providers.dart';

class AdminUserManageSheet {
  AdminUserManageSheet._();

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required Map<String, dynamic> user,
  }) async {
    final userId = user['id']?.toString() ?? '';
    if (userId.isEmpty) return;

    Map<String, dynamic> detail = Map<String, dynamic>.from(user);
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
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Kullanıcı')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'yonetici',
                        child: Text('Yönetici'),
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
                      labelText: 'Üyelik',
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
