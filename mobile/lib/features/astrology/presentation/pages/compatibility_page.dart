import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/util/simple_html_blocks.dart';
import '../../../../core/widgets/discover/discover_tab_pages.dart';
import '../../data/astrology_remote_datasource.dart';
import '../../domain/entities/zodiac_sign.dart';

/// `/astrology/compatibility` — iki burç arasında AI uyum analizi.
class CompatibilityPage extends ConsumerStatefulWidget {
  const CompatibilityPage({super.key});

  @override
  ConsumerState<CompatibilityPage> createState() => _CompatibilityPageState();
}

class _CompatibilityPageState extends ConsumerState<CompatibilityPage> {
  ZodiacSign _first = ZodiacSign.aries;
  ZodiacSign _second = ZodiacSign.leo;
  var _loading = false;
  String? _error;
  List<HtmlBlock> _result = const [];
  (ZodiacSign, ZodiacSign)? _resultPair;

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final html = await ref
          .read(astrologyRemoteDataSourceProvider)
          .compatibility(_first, _second);
      final blocks = parseSimpleHtml(html);
      if (!mounted) return;
      setState(() {
        _result = blocks;
        _resultPair = (_first, _second);
        if (blocks.isEmpty) _error = 'Analiz boş döndü, tekrar dene.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DiscoverSubPage(
      title: 'Burç Uyumu',
      subtitle: 'Aşk, arkadaşlık ve iş uyumu',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: _SignPicker(
                  label: 'Senin burcun',
                  value: _first,
                  onChanged: (v) => setState(() => _first = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.favorite_rounded, color: context.accentPink),
              ),
              Expanded(
                child: _SignPicker(
                  label: 'Onun burcu',
                  value: _second,
                  onChanged: (v) => setState(() => _second = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _loading ? null : _analyze,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_loading ? 'Yıldızlar okunuyor…' : 'Uyumu hesapla'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_result.isNotEmpty && _resultPair != null) ...[
            const SizedBox(height: 18),
            Text(
              '${_resultPair!.$1.symbol} ${_resultPair!.$1.turkishName}  ×  '
              '${_resultPair!.$2.symbol} ${_resultPair!.$2.turkishName}',
              style: TextStyle(
                color: c.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            HtmlBlocksView(blocks: _result),
          ],
        ],
      ),
    );
  }
}

class _SignPicker extends StatelessWidget {
  const _SignPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final ZodiacSign value;
  final ValueChanged<ZodiacSign> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ZodiacSign>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final z in ZodiacSign.values)
          DropdownMenuItem(
            value: z,
            child: Text('${z.symbol} ${z.turkishName}'),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class HtmlBlocksView extends StatelessWidget {
  const HtmlBlocksView({super.key, required this.blocks});

  final List<HtmlBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in blocks)
          Padding(
            padding: EdgeInsets.only(
              top: b.kind == HtmlBlockKind.heading ? 12 : 4,
              bottom: 4,
            ),
            child: switch (b.kind) {
              HtmlBlockKind.heading => Text(
                  b.text,
                  style: TextStyle(
                    color: c.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              HtmlBlockKind.bullet => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: TextStyle(color: c.primary)),
                    Expanded(
                      child: Text(b.text, style: const TextStyle(height: 1.4)),
                    ),
                  ],
                ),
              HtmlBlockKind.paragraph =>
                Text(b.text, style: const TextStyle(height: 1.45)),
            },
          ),
      ],
    );
  }
}
