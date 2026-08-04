import 'package:flutter/material.dart';

import '../theme/voice_room_tokens.dart';
import '../utils/music_az_artists.dart';

/// A-Z harf şeridi + seçilen harfe göre sanatçı çipleri.
class MusicAzLetterBar extends StatefulWidget {
  const MusicAzLetterBar({
    super.key,
    required this.onArtistSelected,
  });

  final ValueChanged<String> onArtistSelected;

  @override
  State<MusicAzLetterBar> createState() => _MusicAzLetterBarState();
}

class _MusicAzLetterBarState extends State<MusicAzLetterBar> {
  String? _selectedLetter;

  @override
  Widget build(BuildContext context) {
    final artists = _selectedLetter == null
        ? const <String>[]
        : MusicAzArtists.forLetter(_selectedLetter!);

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: MusicAzArtists.letters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final letter = MusicAzArtists.letters[index];
                final selected = _selectedLetter == letter;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedLetter = selected ? null : letter;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? VoiceRoomTokens.neonPurple
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? VoiceRoomTokens.neonPurple
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (artists.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: artists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final name = artists[index];
                  return ActionChip(
                    label: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    backgroundColor: VoiceRoomTokens.gold.withValues(alpha: 0.15),
                    side: BorderSide(
                      color: VoiceRoomTokens.gold.withValues(alpha: 0.45),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onArtistSelected(name),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
