import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/agency_management_providers.dart';
import '../widgets/agency_mgmt_widgets.dart';

/// PR #33 — `PATCH /api/agency`
class AgencyProfileEditPage extends ConsumerStatefulWidget {
  const AgencyProfileEditPage({
    super.key,
    required this.initialName,
    this.initialDescription,
  });

  final String initialName;
  final String? initialDescription;

  @override
  ConsumerState<AgencyProfileEditPage> createState() =>
      _AgencyProfileEditPageState();
}

class _AgencyProfileEditPageState extends ConsumerState<AgencyProfileEditPage> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _desc = TextEditingController(text: widget.initialDescription ?? '');
  late final _email = TextEditingController();
  late final _phone = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final msg = await ref.read(agencyManagementProvider).patchAgencyProfile(
            name: _name.text,
            description: _desc.text,
            contactEmail: _email.text,
            contactPhone: _phone.text,
          );
      if (mounted) {
        showResult(context, msg);
        context.pop();
      }
    } catch (e) {
      if (mounted) showResult(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajans bilgileri')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Ajans adı'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Açıklama'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'İletişim e-posta'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'İletişim telefon'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
