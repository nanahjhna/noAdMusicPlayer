import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/app_strings.dart';
import '../../core/design_system.dart';
import '../../core/song_keys.dart';
import 'song_item.dart';

/// Lazily-built list of songs, with now-playing highlighting.
class SongListView extends StatelessWidget {
  const SongListView({
    super.key,
    required this.songs,
    required this.onTap,
    this.onLongPress,
    this.onMenu,
    this.currentKey,
    this.isPlaying = false,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.xl),
  });

  final List<SongModel> songs;
  final void Function(int index) onTap;
  final void Function(SongModel song)? onLongPress;
  final void Function(SongModel song)? onMenu;

  /// Stable key of the playing track, used to highlight its row.
  final String? currentKey;
  final bool isPlaying;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (songs.isEmpty) {
      return Center(
        child: Text(
          strings.noSongsFound,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: padding,
      itemCount: songs.length,
      // Building the key list lazily per row keeps the comparison O(1) instead
      // of scanning the whole queue for every visible row.
      itemBuilder: (context, index) {
        final song = songs[index];
        final isCurrent = currentKey != null && currentKey == stableSongKey(song);
        return SongItem(
          key: ValueKey(stableSongKey(song)),
          song: song,
          isCurrent: isCurrent,
          isPlaying: isPlaying,
          onTap: () => onTap(index),
          onLongPress: onLongPress == null ? null : () => onLongPress!(song),
          onMenu: onMenu == null ? null : () => onMenu!(song),
        );
      },
    );
  }
}
