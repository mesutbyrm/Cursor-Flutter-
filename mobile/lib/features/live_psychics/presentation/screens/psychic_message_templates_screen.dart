import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class PsychicMessageTemplatesScreen extends ConsumerStatefulWidget {
  const PsychicMessageTemplatesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicMessageTemplatesScreen> createState() =>
      _PsychicMessageTemplatesScreenState();
}

class _PsychicMessageTemplatesScreenState
    extends ConsumerState<PsychicMessageTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          centerTitle: true,
          title: const Text(
            'Mesaj Şablonları',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppThemeColors.accentCyan,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Şablonlar'),
              Tab(text: 'Kategoriler'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _TemplatesTab(),
            _CategoriesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateTemplateDialog(context),
          backgroundColor: AppThemeColors.accentCyan,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni Şablon'),
        ),
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedCategory = 'Genel';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yeni Şablon Oluştur',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Şablon Adı',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'örn: Hoşgeldiniz Mesajı',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'İçerik',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  minLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Şablon metninizi yazın...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child:
                          const Text('İptal', style: TextStyle(fontSize: 13)),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            contentController.text.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Şablon oluşturuldu'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppThemeColors.accentCyan,
                      ),
                      child: const Text('Oluştur',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplatesTab extends StatefulWidget {
  @override
  State<_TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends State<_TemplatesTab> {
  late List<Map<String, dynamic>> templates;

  @override
  void initState() {
    super.initState();
    templates = [
      {
        'title': 'Hoşgeldiniz Mesajı',
        'category': 'İlk Seanslar',
        'content':
            'Merhaba! Seansnız başlamak üzere. Lütfen rahat bir ortamda olduğunuzdan emin olun. Soruşturma başlayabiliriz.',
        'usage': 24,
        'created': '15 Şub 2024',
      },
      {
        'title': 'Seans Tamamlanma Notu',
        'category': 'Seans Sonrası',
        'content':
            'Seansımız tamamlandı. Aldığınız tavsiyeler üzerinde düşünmeyi unutmayın. Sorularınız varsa, lütfen bana mesaj atın.',
        'usage': 18,
        'created': '10 Şub 2024',
      },
      {
        'title': 'Takip İçin Hazır',
        'category': 'Takip',
        'content':
            'Seansdan sonra gelişmeler nasıl? Seni takip etmek için sabırsızlanıyorum. Haber verebilir misin?',
        'usage': 12,
        'created': '5 Şub 2024',
      },
      {
        'title': 'Acil Durum Cevabı',
        'category': 'Yanıt',
        'content':
            'Merhaba, mesajını aldım. Şu anda dolu olduğum için, lütfen biraz sonra cevap verebilmemi bekle. Sabrın için teşekkürler.',
        'usage': 8,
        'created': '1 Şub 2024',
      },
      {
        'title': 'Seans Önerisi',
        'category': 'Teklif',
        'content':
            'Düşünüyorum da, daha derinlemesine bir {service} seansı sana çok yardım edebilir. İlgileniyormusun?',
        'usage': 6,
        'created': '25 Oca 2024',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (templates.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.message_outlined, size: 48, color: Colors.white30),
                  const SizedBox(height: 12),
                  Text(
                    'Şablon yok',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ...templates.map((template) => _buildTemplateCard(template)),
      ],
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['title'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            AppThemeColors.accentCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        template['category'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                color: Colors.grey[900],
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 16, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Düzenle', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Şablon düzenlenmek üzere'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Sil',
                            style: TextStyle(fontSize: 13, color: Colors.red)),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        templates.removeWhere(
                            (t) => t['title'] == template['title']);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              template['content'],
              style: const TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.87)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded,
                      size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    '${template['usage']}x kullanıldı',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${template['title']} kopyalandı'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.content_copy_rounded, size: 14),
                    label: const Text('Kopyala'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeColors.accentCyan,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatefulWidget {
  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  late List<Map<String, dynamic>> categories;

  @override
  void initState() {
    super.initState();
    categories = [
      {
        'name': 'İlk Seanslar',
        'description': 'Yeni müşteriler için açılış mesajları',
        'count': 3,
        'color': Colors.green,
      },
      {
        'name': 'Seans Sonrası',
        'description': 'Seansları sonlandırmak için notlar',
        'count': 2,
        'color': Colors.blue,
      },
      {
        'name': 'Takip',
        'description': 'Müşteri takibi ve kontrol mesajları',
        'count': 1,
        'color': Colors.purple,
      },
      {
        'name': 'Yanıt',
        'description': 'Hızlı yanıt şablonları',
        'count': 1,
        'color': Colors.orange,
      },
      {
        'name': 'Teklif',
        'description': 'Ek seans ve paketler için öneriler',
        'count': 1,
        'color': Colors.pink,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Şablon Kategorileri',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...categories.map((category) => _buildCategoryCard(category)),
        const SizedBox(height: 24),
        const Text(
          'Hızlı İpuçları',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          'Her şablona benzersiz bir ad verin',
          'İçerikte {customer_name} veya {service} kullanabilirsiniz',
          'En sık kullanılan şablonları üst sıralara taşıyabilirsiniz',
          'Şablonları yazıyken diğer müşterilerle paylaşabilirsiniz',
        ].map(
          (tip) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 16, color: AppThemeColors.accentCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.87)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (category['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (category['color'] as Color).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['name'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  category['description'],
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (category['color'] as Color).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${category['count']}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: category['color'],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
