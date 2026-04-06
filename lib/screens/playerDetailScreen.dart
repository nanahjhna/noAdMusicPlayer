import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerDetailScreen extends StatefulWidget {
  final SongModel song;
  final AudioPlayer player;
  final bool isPlaying;
  final bool isRepeatOne;
  final Duration duration;
  final Duration position;
  final VoidCallback onToggle;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onRepeatToggle;
  final VoidCallback onStop;

  const PlayerDetailScreen({
    super.key,
    required this.song,
    required this.player,
    required this.isPlaying,
    required this.isRepeatOne,
    required this.duration,
    required this.position,
    required this.onToggle,
    required this.onNext,
    required this.onPrev,
    required this.onRepeatToggle,
    required this.onStop,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final song = widget.song; // 🔥 중요

    return Container(
      key: ValueKey("detail_container_${song.id}"),
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 40),

          QueryArtworkWidget(
            key: ValueKey("artwork_${song.id}"),
            id: song.id,
            type: ArtworkType.AUDIO,
            artworkWidth: double.infinity,
            artworkHeight: 300,
            artworkBorder: BorderRadius.circular(20),
            keepOldArtwork: true,
            artworkQuality: FilterQuality.high,
            format: ArtworkFormat.JPEG,
            nullArtworkWidget: Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.music_note, size: 100, color: Colors.white),
            ),
          ),

          const SizedBox(height: 30),

          Text(
            song.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          Text(
            song.artist ?? "Unknown Artist",
            style: const TextStyle(color: Colors.grey, fontSize: 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          Slider(
            activeColor: const Color(0xFF1DB954),
            inactiveColor: Colors.white24,
            value: widget.position.inSeconds
                .toDouble()
                .clamp(0, widget.duration.inSeconds.toDouble()),
            max: widget.duration.inSeconds > 0
                ? widget.duration.inSeconds.toDouble()
                : 1.0,
            onChanged: (value) async {
              await widget.player.seek(Duration(seconds: value.toInt()));
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(widget.position),
                    style: const TextStyle(color: Colors.grey)),
                Text(_formatDuration(widget.duration),
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  widget.isRepeatOne
                      ? Icons.repeat_one_on_rounded
                      : Icons.repeat_rounded,
                  color: widget.isRepeatOne
                      ? const Color(0xFF1DB954)
                      : Colors.white,
                  size: 30,
                ),
                onPressed: widget.onRepeatToggle,
              ),

              IconButton(
                icon: const Icon(Icons.skip_previous,
                    size: 45, color: Colors.white),
                onPressed: widget.onPrev,
              ),

              IconButton(
                icon: Icon(
                  widget.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 80,
                  color: Colors.white,
                ),
                onPressed: widget.onToggle,
              ),

              IconButton(
                icon: const Icon(Icons.skip_next,
                    size: 45, color: Colors.white),
                onPressed: widget.onNext,
              ),

              IconButton(
                icon: const Icon(Icons.stop,
                    size: 35, color: Colors.white),
                onPressed: widget.onStop,
              ),

              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 30, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds =
    (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}