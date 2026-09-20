import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/staff_access_provider.dart';

/// Admin — E-posta şablonları yönetimi.
class AdminEmailTemplatesPage extends ConsumerStatefulWidget {
  const AdminEmailTemplatesPage({super.key});

  @override
  ConsumerState<AdminEmailTemplatesPage> createState() => _AdminEmailTemplatesPageState();
}

class _AdminEmailTemplatesPageState extends ConsumerState<AdminEmailTemplatesPage> {
  final List<Map<String, dynamic>> templates = [
    {
      'id': 'welcome_email',
      'name': 'Hoşgeldiniz E-postası',
      'description': 'Yeni kullanıcılara gönderilen karşılama e-postası',
      'category': 'Kimlik Doğrulama',
      'enabled': true,
      'lastModified': '2025-01-15',
    },
    {
      'id': 'password_reset',
      'name': 'Şifre Sıfırlama',
      'description': 'Şifre yenileme istekleri için e-posta',
      'category': 'Kimlik Doğrulama',
      'enabled': true,
      'lastModified': '2025-01-10',
    },
    {
      'id': 'payment_confirmation',
      'name': 'Ödeme Onayı',
      'description': 'Başarılı ödeme işlemlerinden sonra gönderilen e-posta',
      'category': 'Finansman',
      'enabled': true,
      'lastModified': '2025-01-05',
    },
    {
      'id': 'payment_failed',
      'name': 'Ödeme Başarısız',
      'description': 'Başarısız ödeme işlemi hakkında bilgilendirme',
      'category': 'Finansman',
      'enabled': true,
      'lastModified': '2024-12-28',
    },
    {
      'id': 'session_ended',
      'name': 'Oturum Sonlandırma',
      'description': 'Falcı oturumu sonlandırıldığında gönderilen e-posta',
      'category': 'Hizmet',
      'enabled': true,
      'lastModified': '2024-12-20',
    },
    {
      'id': 'account_suspended',
      'name': 'Hesap Askıya Alındı',
      'description': 'Hesap askıya alındığında gönderilen bildirim',
      'category': 'Uyarı',
      'enabled': true,
      'lastModified': '2024-12-15',
    },
    {
      'id': 'promotional_offer',
      'name': 'Promosyon Teklifi',
      'description': 'Aylık promosyon ve özel teklifler',
      'category': 'Pazarlama',
      'enabled': false,
      'lastModified': '2024-12-10',
    },
    {
      'id': 'verification_reminder',
      'name': 'Doğrulama Hatırlatması',
      'description': 'Kimlik doğrulama tamamlanmadığında hatırlatma',
      'category': 'Kimlik Doğrulama',
      'enabled': true,
      'lastModified': '2024-12-01',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isSiteAdmin && !access.isFounder) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'E-posta şablonları yalnızca site admin tarafından yönetilir.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'E-posta Şablonları',
                      subtitle: 'Sistem bildirimleri ve müşteri iletişimi',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.add_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final template = templates[i];
                  return _TemplateCard(
                    template: template,
                    onEdit: () => _showTemplateEditor(context, template),
                    onToggle: (enabled) {
                      setState(() => template['enabled'] = enabled);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateEditor(BuildContext context, Map<String, dynamic> template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TemplateEditorSheet(template: template),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onToggle,
  });

  final Map<String, dynamic> template;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Kimlik Doğrulama':
        return Colors.blue;
      case 'Finansman':
        return Colors.green;
      case 'Hizmet':
        return AppThemeColors.accentCyan;
      case 'Uyarı':
        return Colors.orange;
      case 'Pazarlama':
        return AppThemeColors.accentPink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: (template['enabled'] as bool)
          ? AppThemeColors.accentCyan.withValues(alpha: 0.08)
          : Colors.grey.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template['name']?.toString() ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(template['category']).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getCategoryColor(template['category']).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              template['category']?.toString() ?? '—',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryColor(template['category']),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Düzenleme: ${template['lastModified']?.toString() ?? '—'}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: template['enabled'] as bool,
                  onChanged: onToggle,
                  activeColor: AppThemeColors.accentCyan,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              template['description']?.toString() ?? '—',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.preview_rounded, size: 16),
                  label: const Text('Ön izle'),
                  onPressed: onEdit,
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Düzenle'),
                  onPressed: onEdit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateEditorSheet extends StatefulWidget {
  const _TemplateEditorSheet({required this.template});
  final Map<String, dynamic> template;

  @override
  State<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<_TemplateEditorSheet> {
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: 'Konu başlığı');
    _bodyController = TextEditingController(
      text: '''Merhaba {{userName}},

Bu, örnek bir e-posta şablonudur. Aşağıdaki değişkenleri kullanabilirsiniz:
- {{userName}}: Kullanıcı adı
- {{email}}: E-posta adresi
- {{date}}: Geçerli tarih
- {{supportEmail}}: Destek e-postası

Lütfen {{supportEmail}} ile iletişime geçin.

Saygılarımızla,
Canlifal Ekibi''',
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.template['name']?.toString() ?? '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  const Text('Konu', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('İçerik', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bodyController,
                    maxLines: 10,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Şablon kaydedildi')),
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
