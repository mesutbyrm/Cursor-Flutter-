import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../providers/parity_providers.dart';
import '../widgets/parity_widgets.dart';

/// İletişim formu (POST /api/contact).
class ContactPage extends ConsumerStatefulWidget {
  const ContactPage({super.key});

  @override
  ConsumerState<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends ConsumerState<ContactPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _msg = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _msg.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final msg = _msg.text.trim();
    if (name.isEmpty || !email.contains('@') || msg.length < 5) {
      parityToast(context, 'Ad, geçerli e-posta ve mesaj gerekli');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(parityApiProvider)
          .rawPost('/api/contact', {'name': name, 'email': email, 'message': msg});
      _msg.clear();
      if (mounted) parityToast(context, 'Mesajın gönderildi, teşekkürler');
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MockScaffold(
      title: 'İletişim',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Adın', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'E-posta', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _msg,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
                labelText: 'Mesajın', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}
