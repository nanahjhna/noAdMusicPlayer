import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../core/app_strings.dart';
import '../core/design_system.dart';
import '../core/playback_controller.dart';
import '../core/song_keys.dart';
import 'artwork.dart';
import 'song_actions.dart';

/// Persistent mini player docked above the navigation bar.
///
/// Note there is deliberately no close button: the previous implementation's X
/// called `player.stop()`, which killed playback and (because
/// `androidStopForegroundOnPause` is set) removed the notification too, leaving
/// no way back. The bar stays while a queue is loaded; the trailing action adds
/// the playing track to a playlist.
class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({
    super.key,
    required this.controller,
    required this.onExpand,
  });

  final PlaybackController controller;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final song = controller.currentSong;
    if (song == null) return const SizedBox.shrink();

    return StreamBuilder<SequenceState?>(
      stream: controller.player.sequenceStateStream,
      builder: (context, snapshot) {
        return StreamBuilder<Duration>(
          stream: controller.player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = controller.player.duration ?? Duration.zero;
            final totalMs = duration.inMilliseconds;
            final progress = totalMs > 0
                ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
                : 0.0;

            return Semantics(
              button: true,
              label: strings.nowPlaying,
              child: GestureDetector(
                onTap: onExpand,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border(
                      top: BorderSide(color: AppColors.divider, width: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hairline progress so the bar reads as a live player.
                      SizedBox(
                        height: 2,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.surfaceHigh,
                          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                      SizedBox(
                        height: AppSizes.miniBarHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Hero(
                                tag: 'art_${stableSongKey(song)}',
                                child: SongArtwork(
                                  songId: song.id,
                                  size: AppSizes.artworkMini,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      song.artist?.trim().isNotEmpty == true
                                          ? song.artist!.trim()
                                          : strings.unknownArtist,
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
                              _TransportButton(
                                icon: Icons.skip_previous_rounded,
                                size: 24,
                                tooltip: strings.previous,
                                onTap: controller.skipPreviousOrRestart,
                              ),
                              StreamBuilder<bool>(
                                stream: controller.player.playingStream,
                                builder: (context, playingSnapshot) {
                                  final isPlaying = playingSnapshot.data ?? false;
                                  return _TransportButton(
                                    icon: isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 28,
                                    tooltip: isPlaying ? strings.pause : strings.play,
                                    onTap: controller.togglePlayPause,
                                  );
                                },
                              ),
                              _TransportButton(
                                icon: Icons.skip_next_rounded,
                                size: 24,
                                tooltip: strings.next,
                                onTap: controller.skipNext,
                              ),
                              _TransportButton(
                                icon: Icons.playlist_add_rounded,
                                size: 26,
                                tooltip: strings.addToPlaylist,
                                onTap: () => showSongActions(
                                  context,
                                  song: song,
                                  onChanged: (_) {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      splashRadius: 22,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(AppSpacing.xs),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Icon(icon, size: size, color: AppColors.textPrimary),
    );
  }
}
