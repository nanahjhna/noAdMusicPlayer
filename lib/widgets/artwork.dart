import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/design_system.dart';

/// Three animated bars shown on the row that is currently playing.
///
/// Every commercial player highlights the active row; without it there is no
/// way to tell which track the mini player is playing.
class PlayingIndicator extends StatefulWidget {
  const PlayingIndicator({super.key, required this.isPlaying});

  /// When false the bars freeze at a static "paused" pose.
  final bool isPlaying;

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(PlayingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final phase in const [0.0, 0.33, 0.66]) _bar(_controller.value + phase),
          ],
        ),
      ),
    );
  }

  Widget _bar(double t) {
    // Three-phase sine so the bars rise and fall out of sync with each other.
    final wave = (t + 0.0) % 1.0 * 2 * math.pi;
    final height = widget.isPlaying
        ? 4 + 12 * (0.5 + 0.5 * math.sin(wave))
        : 6.0;
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Album art for a track, shared by the list row, mini player and full player.
///
/// Sized and rounded consistently everywhere so the Hero transition in and out
/// of the full-screen player lines up.
class SongArtwork extends StatelessWidget {
  const SongArtwork({
    super.key,
    required this.songId,
    required this.size,
    this.borderRadius,
    this.quality,
  });

  final int songId;
  final double size;
  final BorderRadius? borderRadius;
  final FilterQuality? quality;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.sm);
    return QueryArtworkWidget(
      id: songId,
      type: ArtworkType.AUDIO,
      artworkWidth: size,
      artworkHeight: size,
      artworkQuality: quality ?? FilterQuality.low,
      artworkBorder: radius,
      keepOldArtwork: true,
      nullArtworkWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: radius),
        child: Icon(
          Icons.music_note_rounded,
          color: AppColors.textTertiary,
          size: size * 0.4,
        ),
      ),
    );
  }
}
