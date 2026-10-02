import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/app_strings.dart';
import '../core/design_system.dart';
import '../core/playback_controller.dart';
import 'artwork.dart';

/// Bottom sheet listing the loaded queue in the order it will actually play.
///
/// The app previously had no queue view at all, so "why is this song playing"
/// was unanswerable. The list is permuted through
/// [PlaybackController.playbackOrder] so it matches what the listener hears
/// when shuffle is on.
class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key, required this.controller});

  final PlaybackController controller;

  static Future<void> show(BuildContext context, PlaybackController controller) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (_) => QueueSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final songs = controller.queue;
        final order = controller.playbackOrder;
        final current = controller.currentIndex;
        final playing = controller.player.playing;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const _Grabber(),
                _Header(controller: controller, songCount: songs.length),
                if (songs.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        strings.noPlayingSong,
                        style: const TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      itemCount: order.length,
                      itemBuilder: (context, position) {
                        final queueIndex = order[position];
                        final song = songs[queueIndex];
                        final isCurrent = queueIndex == current;
                        return _QueueRow(
                          song: song,
                          isCurrent: isCurrent,
                          isPlaying: isCurrent && playing,
                          onTap: () => controller.jumpTo(queueIndex),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.songCount});

  final PlaybackController controller;
  final int songCount;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final source = controller.queueSourceLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.queue, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  source.isEmpty ? '$songCount ${strings.songsCount}' : source,
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
          IconButton(
            tooltip: strings.clearQueue,
            onPressed: () {
              Navigator.of(context).pop();
              controller.stopAndClear();
            },
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  final SongModel song;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final artist = song.artist?.trim() ?? '';

    return ListTile(
      onTap: onTap,
      selected: isCurrent,
      selectedTileColor: AppColors.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: SizedBox(
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
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent ? AppColors.accent : AppColors.textPrimary,
          fontSize: 14,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        artist.isEmpty ? strings.unknownArtist : artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
      ),
    );
  }
}
