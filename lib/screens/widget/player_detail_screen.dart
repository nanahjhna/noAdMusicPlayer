import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/app_strings.dart';
import '../../core/design_system.dart';
import '../../core/playback_controller.dart';
import '../../core/song_keys.dart';
import '../../widgets/artwork.dart';
import '../../widgets/song_actions.dart';


/// Full-screen "now playing" view.
///
/// Reached from the mini player with a Hero transition on the artwork.
/// Shuffle/loop route through [PlaybackController] — the previous version
/// called the player directly, which skipped persistence and made the modes
/// reset on every launch.
class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key, required this.controller});

  final PlaybackController controller;

  static Route<void> route(PlaybackController controller) {
    return PageRouteBuilder<void>(
      transitionDuration: AppMotion.slow,
      reverseTransitionDuration: AppMotion.normal,
      pageBuilder: (_, __, ___) => PlayerDetailScreen(controller: controller),
      transitionsBuilder: (_, animation, __, child) {
        final curved = animation.drive(CurveTween(curve: AppMotion.enter));
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final song = controller.currentSong;

        if (song == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                strings.noPlayingSong,
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ),
          );
        }

        return PopScope(
          canPop: true,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: GestureDetector(
              // Swipe down to dismiss, matching the mini-player gesture.
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 400) Navigator.of(context).pop();
              },
              behavior: HitTestBehavior.translucent,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Artwork scales with the viewport instead of a fixed 300px,
                    // so the layout holds up on tablets and in landscape.
                    final artwork = (constraints.maxWidth - AppSpacing.xl * 2)
                        .clamp(120.0, AppSizes.artworkFull);

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _TopBar(controller: controller, song: song),
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            child: Column(
                              children: [
                                Hero(
                                  tag: 'art_${stableSongKey(song)}',
                                  child: SongArtwork(
                                    songId: song.id,
                                    size: artwork,
                                    quality: FilterQuality.medium,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _Titles(song: song),
                                const SizedBox(height: AppSpacing.lg),
                                _SeekBar(controller: controller),
                                const SizedBox(height: AppSpacing.sm),
                                _TransportRow(controller: controller),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.song});

  final PlaybackController controller;
  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: strings.collapsePlayer,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 32,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  strings.nowPlaying,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.queueSourceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showSongActions(
              context,
              song: song,
              onChanged: (_) {},
            ),
            tooltip: strings.addToPlaylist,
            icon: const Icon(
              Icons.playlist_add_rounded,
              size: 26,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final artist = song.artist?.trim() ?? '';
    final album = song.album?.trim() ?? '';

    return Column(
      children: [
        Text(
          song.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          [
            if (artist.isNotEmpty) artist,
            if (album.isNotEmpty) album,
          ].join(' · '),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        if (artist.isEmpty && album.isEmpty)
          Text(
            strings.unknownArtist,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
      ],
    );
  }
}

/// Seek bar with drag-local state.
///
/// The previous implementation seeked on every `onChanged` tick, which floods
/// the decoder and causes audible stutter on low-end devices. It also read
/// `player.duration` outside a stream, so the track length could flash during
/// a transition.
class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.controller});

  final PlaybackController controller;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.controller.player.positionStream,
      builder: (context, snapshot) {
        return StreamBuilder<Duration?>(
          stream: widget.controller.player.durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final totalMs = duration.inMilliseconds;
            final positionMs = _dragValue ?? snapshot.data?.inMilliseconds ?? 0;
            final maxMs = totalMs > 0 ? totalMs.toDouble() : 1.0;
            final value = positionMs.toDouble().clamp(0.0, maxMs);
            final canSeek = totalMs > 0;

            return Column(
              children: [
                Slider(
                  value: value,
                  max: maxMs,
                  onChanged: canSeek
                      ? (next) => setState(() => _dragValue = next)
                      : null,
                  // Single seek when the finger lifts, not per pixel.
                  onChangeEnd: canSeek
                      ? (next) {
                          widget.controller.seek(
                            Duration(milliseconds: next.round()),
                          );
                          setState(() => _dragValue = null);
                        }
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _format(Duration(milliseconds: positionMs.round())),
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _format(duration),
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _format(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final minutes = safe.inMinutes.toString().padLeft(2, '0');
    final seconds = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow({required this.controller});

  final PlaybackController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StreamBuilder<bool>(
          stream: controller.player.shuffleModeEnabledStream,
          builder: (context, snapshot) {
            final active = snapshot.data ?? controller.shuffleEnabled;
            return _ModeButton(
              icon: Icons.shuffle_rounded,
              tooltip: strings.shuffle,
              active: active,
              onTap: controller.toggleShuffle,
            );
          },
        ),
        IconButton(
          onPressed: controller.skipPreviousOrRestart,
          tooltip: strings.previous,
          iconSize: 42,
          icon: const Icon(
            Icons.skip_previous_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        StreamBuilder<bool>(
          stream: controller.player.playingStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            return _PlayButton(
              isPlaying: isPlaying,
              onTap: controller.togglePlayPause,
            );
          },
        ),
        IconButton(
          onPressed: controller.skipNext,
          tooltip: strings.next,
          iconSize: 42,
          icon: const Icon(
            Icons.skip_next_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        StreamBuilder<LoopMode>(
          stream: controller.player.loopModeStream,
          builder: (context, snapshot) {
            final mode = snapshot.data ?? controller.loopMode;
            return _ModeButton(
              icon: mode == LoopMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              tooltip: switch (mode) {
                LoopMode.one => strings.repeatOne,
                LoopMode.all => strings.repeatAll,
                LoopMode.off => strings.repeatOff,
              },
              active: mode != LoopMode.off,
              onTap: controller.cycleLoopMode,
            );
          },
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.textPrimary,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: AppSizes.playButton,
            height: AppSizes.playButton,
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 40,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: 24,
        color: active ? AppColors.accent : AppColors.textTertiary,
      ),
    );
  }
}
