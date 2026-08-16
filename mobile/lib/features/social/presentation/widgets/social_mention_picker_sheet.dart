import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../search/domain/entities/search_user_entity.dart';
import '../../../search/presentation/providers/search_providers.dart';

/// Sosyal paylaşımda kullanıcı etiketleme seçici.
class SocialMentionPickerSheet extends ConsumerStatefulWidget {
  const SocialMentionPickerSheet({super.key});

  @override
  ConsumerState<SocialMentionPickerSheet> createState() =>
      _SocialMentionPickerSheetState();
}

class _SocialMentionPickerSheetState
    extends ConsumerState<SocialMentionPickerSheet> {
  final _query = TextEditingController();
  var _loading = false;
  List<SearchUserEntity> _results = const [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await ref.read(searchRemoteProvider).searchUsers(q.trim());
      if (mounted) setState(() => _results = list);
    } catch (_) {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Kişi etiketle',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _query,
                decoration: InputDecoration(
                  hintText: 'Kullanıcı adı ara…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _search,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final u = _results[i];
                        return ListTile(
                          leading: UserAvatar(url: u.image, radius: 18),
                          title: Text(u.name),
                          subtitle: Text('@${u.username}'),
                          onTap: () => Navigator.pop(context, u),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
