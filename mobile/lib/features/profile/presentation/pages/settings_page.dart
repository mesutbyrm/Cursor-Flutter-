import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import 'settings_category_page.dart';

/// Ayarlar — her kategori tek satırlık kart; sağ üstte arama ile süzülür.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  var _searching = false;
  var _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<SettingsCategoryData> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return settingsCategories;
    return [
      for (final c in settingsCategories)
        if (c.title.toLowerCase().contains(q) ||
            c.subtitle.toLowerCase().contains(q))
          c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = _filtered;
    return MockScaffold(
      title: 'Ayarlar',
      actions: [
        IconButton(
          tooltip: _searching ? 'Aramayı kapat' : 'Ara',
          icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
          color: c.onSurface,
          onPressed: () => setState(() {
            _searching = !_searching;
            if (!_searching) {
              _query = '';
              _controller.clear();
            }
          }),
        ),
      ],
      body: Column(
        children: [
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Ayarlarda ara',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: mockCardColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: mockCardBorder(context)),
                  ),
                ),
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Sonuç bulunamadı',
                      style: TextStyle(color: c.onSurfaceMuted),
                    ),
                  )
                : MockRowList(
                    gap: 5,
                    children: [
                      for (final cat in items)
                        MockListRow(
                          icon: cat.icon,
                          color: cat.accent,
                          title: cat.title,
                          subtitle: cat.subtitle,
                          onTap: () => context.push(cat.route),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
