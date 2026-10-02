import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/app_strings.dart';
import '../../core/design_system.dart';
import '../../core/song_keys.dart';
import '../../widgets/artwork.dart';

/// Playlist row with a drag handle.
///
/// Uses [ReorderableDragStartListener] rather than
/// [ReorderableDelayedDragStartListener] so a long-press anywhere on the row
/// still opens the action sheet — the handle is the only drag affordance.
class SongListRow extends StatelessWidget {
  const SongListRow({
    super.key,
    required this.index,
    required this.song,
    required this.onTap,
    this.onLongPress,
    this.isCurrent = false,
    this.isPlaying = false,
  });

  final int index;
  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isCurrent;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final artist = song.artist?.trim() ?? '';

    return Material(
      color: isCurrent ? AppColors.surface : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: AppSizes.artworkList,
                height: AppSizes.artworkList,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SongArtwork(songId: song.id, size: AppSizes.artworkList),
                    if (isCurrent)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(child: PlayingIndicator(isPlaying: isPlaying)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? AppColors.accent : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artist.isEmpty ? strings.unknownArtist : artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in a song list.
class SongItem extends StatelessWidget {
  const SongItem({
    super.key,
    required this.song,
    required this.onTap,
    this.onLongPress,
    this.onMenu,
    this.isCurrent = false,
    this.isPlaying = false,
    this.trailing,
  });

  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMenu;

  /// Whether this row is the track in the player right now.
  final bool isCurrent;
  final bool isPlaying;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final artist = song.artist?.trim() ?? '';

    return Material(
      color: isCurrent ? AppColors.surface : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: AppSizes.artworkList,
                height: AppSizes.artworkList,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SongArtwork(
                      key: ValueKey('list_art_${stableSongKey(song)}'),
                      songId: song.id,
                      size: AppSizes.artworkList,
                    ),
                    if (isCurrent)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(child: PlayingIndicator(isPlaying: isPlaying)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? AppColors.accent : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artist.isEmpty ? strings.unknownArtist : artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onMenu != null)
                IconButton(
                  onPressed: onMenu,
                  tooltip: strings.fileInfo,
                  splashRadius: 20,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
