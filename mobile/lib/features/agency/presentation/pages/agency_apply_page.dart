import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../providers/agency_providers.dart';

/// Ajans ol — `POST /api/agency/apply`. Başvuru admin onayına düşer.
class AgencyApplyPage extends ConsumerStatefulWidget {
  const AgencyApplyPage({super.key});

  @override
  ConsumerState<AgencyApplyPage> createState() => _AgencyApplyPageState();
}

class _AgencyApplyPageState extends ConsumerState<AgencyApplyPage> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 3) {
      setState(() => _error = 'Ajans adı en az 3 karakter olmalıdır');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final msg = await ref.read(agencyRemoteProvider).applyForAgency(
            name: name,
            description: _desc.text.trim(),
            contactEmail: _email.text.trim(),
            contactPhone: _phone.text.trim(),
          );
      await ref.read(approvedAgencyProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (context.canPop()) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = ApiException.userMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: mockCardColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: mockCardBorder(context)),
          ),
        );
    return MockScaffold(
      title: 'Ajans Ol',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
        children: [
          Card(
            child: ListTile(
              key: const Key('apply-discover-agencies'),
              leading: const Icon(Icons.travel_explore_rounded),
              title: const Text('Bir ajansa katılmak mı istiyorsun?'),
              subtitle: const Text('Ajansları, vaatlerini ve gerçek performanslarını incele; başvur.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/ajanslar'),
            ),
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => context.push('/ajans/davetler'),
                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                label: const Text('Ajans davetlerim'),
              ),
              TextButton.icon(
                onPressed: () => context.push('/ajans/yayinci'),
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Yayıncı panelim'),
              ),
            ],
          ),
          const Text(
            'Ajansını kur, yayıncıları topla. Başvurun admin onayına gönderilir.',
            style: TextStyle(fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            decoration: deco('Ajans adı', Icons.apartment_rounded),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: deco('Açıklama (isteğe bağlı)', Icons.notes_rounded),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: deco('İletişim e-postası (isteğe bağlı)', Icons.email_outlined),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: deco('İletişim telefonu (isteğe bağlı)', Icons.phone_outlined),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFF5A6A), fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Başvuru Gönder'),
          ),
        ],
      ),
    );
  }
}
