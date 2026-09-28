import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dream_contest_entity.dart';
import '../providers/dream_provider.dart';

class ContestEntriesList extends ConsumerStatefulWidget {
  final String contestId;

  const ContestEntriesList({
    Key? key,
    required this.contestId,
  }) : super(key: key);

  @override
  ConsumerState<ContestEntriesList> createState() => _ContestEntriesListState();
}

class _ContestEntriesListState extends ConsumerState<ContestEntriesList> {
  Future<void> _voteEntry(String entryId) async {
    try {
      final repository = ref.read(dreamRepositoryProvider);
      await repository.voteContestEntry(widget.contestId, entryId);
      ref.read(votedEntriesProvider.notifier).state = {
        ...ref.read(votedEntriesProvider),
        entryId,
      };
      ref.refresh(contestEntriesProvider(widget.contestId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oy başarıyla verildi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(contestEntriesProvider(widget.contestId));
    final votedEntries = ref.watch(votedEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Henüz katılım yok'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final hasVoted = votedEntries.contains(entry.id);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                              Row(
                                children: [
                                  if (entry.avatarUrl != null)
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          NetworkImage(entry.avatarUrl!),
                                      onBackgroundImageError: (_, __) {},
                                    )
                                  else
                                    const CircleAvatar(
                                      radius: 20,
                                      child: Icon(Icons.person),
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (entry.isWinner)
                                          const Text(
                                            '🏆 Kazanan',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${entry.votes} oy',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.dreamText,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            hasVoted ? null : () => _voteEntry(entry.id),
                        icon: Icon(hasVoted ? Icons.done : Icons.thumb_up),
                        label: Text(hasVoted ? 'Oy Verildi' : 'Oy Ver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              hasVoted ? Colors.grey : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    );
  }
}
