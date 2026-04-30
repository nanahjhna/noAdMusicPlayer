import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../services/audioManager.dart';
import '../../app_strings.dart'; // 경로 확인 필요

class PlayerDetailScreen extends StatelessWidget {
  final AudioManager audioManager;

  const PlayerDetailScreen({
    super.key,
    required this.audioManager,
  });

  String _formatDuration(Duration? d) {
    if (d == null) return "00:00";
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 [에러 해결] 이 줄이 반드시 build 함수 최상단에 있어야 합니다!
    final strings = AppStrings.of(context);

    return StreamBuilder<SequenceState?>(
      stream: audioManager.player.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;

        // 재생 중인 곡이 없을 때 처리
        if (state == null || state.currentSource == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                strings.noPlayingSong, // 이제 에러가 나지 않습니다.
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final metadata = state.currentSource!.tag as MediaItem;

        return Scaffold(
          backgroundColor: Colors.grey[900],
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // 상단 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 35),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      strings.nowPlaying, // "NOW PLAYING"
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const Spacer(),

                // 앨범 아트
                Center(
                  child: QueryArtworkWidget(
                    id: int.parse(metadata.id),
                    type: ArtworkType.AUDIO,
                    artworkWidth: 300,
                    artworkHeight: 300,
                    artworkBorder: BorderRadius.circular(20),
                    nullArtworkWidget: Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.music_note, size: 100, color: Colors.white24),
                    ),
                  ),
                ),
                const Spacer(),

                // 제목 및 아티스트
                Column(
                  children: [
                    Text(
                      metadata.title,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      metadata.artist ?? strings.unknownArtist,
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // 재생바 (Slider)
                StreamBuilder<Duration>(
                  stream: audioManager.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = audioManager.player.duration ?? Duration.zero;

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbColor: const Color(0xFF1DB954),
                            activeTrackColor: const Color(0xFF1DB954),
                            inactiveTrackColor: Colors.white12,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          ),
                          child: Slider(
                            value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                            max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
                            onChanged: (value) {
                              audioManager.player.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 컨트롤 버튼 (셔플, 이전곡, 재생, 다음곡, 반복)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 셔플 버튼
                    StreamBuilder<bool>(
                      stream: audioManager.player.shuffleModeEnabledStream,
                      builder: (context, snapshot) {
                        final isShuffle = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(Icons.shuffle_rounded,
                              color: isShuffle ? const Color(0xFF1DB954) : Colors.white54),
                          onPressed: () => audioManager.player.setShuffleModeEnabled(!isShuffle),
                        );
                      },
                    ),

                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white),
                      onPressed: () => audioManager.player.seekToPrevious(),
                    ),

                    // 재생/일시정지
                    StreamBuilder<bool>(
                      stream: audioManager.player.playingStream,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return GestureDetector(
                          onTap: () => isPlaying ? audioManager.pause() : audioManager.play(),
                          child: Container(
                            height: 70,
                            width: 70,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 45,
                              color: Colors.black,
                            ),
                          ),
                        );
                      },
                    ),

                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white),
                      onPressed: () => audioManager.player.seekToNext(),
                    ),

                    // 반복 버튼
                    StreamBuilder<LoopMode>(
                      stream: audioManager.player.loopModeStream,
                      builder: (context, snapshot) {
                        final loopMode = snapshot.data ?? LoopMode.off;
                        return IconButton(
                          icon: Icon(
                            loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                            color: loopMode != LoopMode.off ? const Color(0xFF1DB954) : Colors.white54,
                          ),
                          onPressed: () {
                            if (loopMode == LoopMode.off) {
                              audioManager.player.setLoopMode(LoopMode.all);
                            } else if (loopMode == LoopMode.all) {
                              audioManager.player.setLoopMode(LoopMode.one);
                            } else {
                              audioManager.player.setLoopMode(LoopMode.off);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }
}