import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dream_provider.dart';
import '../widgets/dream_contest_card.dart';
import '../widgets/contest_entries_list.dart';

class DreamContestPage extends ConsumerStatefulWidget {
  const DreamContestPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DreamContestPage> createState() => _DreamContestPageState();
}

class _DreamContestPageState extends ConsumerState<DreamContestPage> {
  final TextEditingController _dreamController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _dreamController.dispose();
    super.dispose();
  }

  Future<void> _submitDreamEntry(String contestId) async {
    if (_dreamController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rüyayı yazınız')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(dreamRepositoryProvider);
      await repository.postContestEntry(contestId, _dreamController.text);
      _dreamController.clear();
      ref.refresh(contestEntriesProvider(contestId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rüyanız başarıyla gönderildi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contestAsync = ref.watch(dreamContestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rüya Yarışması'),
        elevation: 0,
      ),
      body: contestAsync.when(
        data: (contest) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DreamContestCard(contest: contest),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rüyanızı Paylaşın',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dreamController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Gördüğünüz rüyayı açıklayınız...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitDreamEntry(contest.id),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Gönder'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Yarışma Katılımcıları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ContestEntriesList(contestId: contest.id),
            ],
          ),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Hata: $error'),
          ),
        ),
      ),
    );
  }
}
