import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/ai_copilot_provider.dart';

class AICopilotScreen extends ConsumerStatefulWidget {
  const AICopilotScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AICopilotScreen> createState() => _AICopilotScreenState();
}

class _AICopilotScreenState extends ConsumerState<AICopilotScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _selectedAnalysisType = 'general';
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Copilot'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.cyan[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyan[200]!),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                underline: const SizedBox(),
                value: _selectedAnalysisType,
                onChanged: (value) {
                  setState(() {
                    _selectedAnalysisType = value ?? 'general';
                  });
                },
                items: [
                  DropdownMenuItem(
                    value: 'general',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology_alt, color: Colors.cyan),
                          const SizedBox(width: 8),
                          const Text('Genel Analiz'),
                        ],
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'compatibility',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.pink),
                          const SizedBox(width: 8),
                          const Text('Uyum Analizi'),
                        ],
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'insight',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.amber),
                          const SizedBox(width: 8),
                          const Text('Derinlemesine İçgörü'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final suggestionsAsync = ref.watch(
                  aiCopilotSuggestionsProvider((
                    limit: _pageSize,
                    offset: _currentPage * _pageSize,
                  )),
                );

                return suggestionsAsync.when(
                  data: (suggestions) {
                    if (suggestions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 64,
                              color: Colors.cyan[200],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Henüz AI önerisi yok',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Bir soru sorun veya fal okumasından yardım alın',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return _buildSuggestionCard(context, ref, suggestion);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text('Hata: $err'),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'AI Copilot\'a bir soru sorun...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: Icon(
                      Icons.edit,
                      color: Colors.cyan[300],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final generateState = ref.watch(generateSuggestionProvider);
                      final isLoading = generateState.isLoading;

                      return ElevatedButton.icon(
                        icon: isLoading ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ) : const Icon(Icons.auto_awesome),
                        label: Text(isLoading ? 'Analiz Ediliyor...' : 'AI Önerisi Al'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: isLoading ? null : () => _generateSuggestion(ref),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    WidgetRef ref,
    AICopilotSuggestion suggestion,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.cyan[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getAnalysisTypeLabel(suggestion.analysisType),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.cyan,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(suggestion.confidenceScore),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(suggestion.confidenceScore * 100).toInt()}% Güven',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        suggestion.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            suggestion.liked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(suggestion.liked ? 'Beğenmekten Çık' : 'Beğen'),
                        ],
                      ),
                      onTap: () => _toggleLike(ref, suggestion.id),
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Sil'),
                        ],
                      ),
                      onTap: () => _deleteSuggestion(context, ref, suggestion.id),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              suggestion.suggestion,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('d MMMM HH:mm', 'tr_TR').format(suggestion.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAnalysisTypeLabel(String type) {
    switch (type) {
      case 'general':
        return 'Genel';
      case 'compatibility':
        return 'Uyum';
      case 'insight':
        return 'İçgörü';
      default:
        return type;
    }
  }

  Color _getConfidenceColor(double score) {
    if (score > 0.8) {
      return Colors.green[400]!;
    } else if (score > 0.6) {
      return Colors.amber[400]!;
    } else {
      return Colors.orange[400]!;
    }
  }

  void _generateSuggestion(WidgetRef ref) {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir soru giriniz')),
      );
      return;
    }

    final notifier = ref.read(generateSuggestionProvider.notifier);
    notifier.generate(
      prompt: _promptController.text,
      analysisType: _selectedAnalysisType,
    );
    _promptController.clear();
    ref.invalidate(aiCopilotSuggestionsProvider);
  }

  void _toggleLike(WidgetRef ref, String suggestionId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Öneriniz kaydedildi')),
    );
  }

  void _deleteSuggestion(BuildContext context, WidgetRef ref, String suggestionId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Öneriler silindi')),
    );
    ref.invalidate(aiCopilotSuggestionsProvider);
  }
}
