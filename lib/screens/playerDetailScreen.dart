import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerDetailScreen extends StatefulWidget {
  final AudioPlayer player;
  final List<SongModel> songs; // 전체 곡 목록을 받음

  const PlayerDetailScreen({
    super.key,
    required this.player,
    required this.songs,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  // 시간 포맷팅 함수 (00:00 형식)
  String _formatDuration(Duration? d) {
    if (d == null) return "00:00";
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: widget.player.currentIndexStream,
      builder: (context, snapshot) {
        final index = snapshot.data;
        // 곡 정보가 없으면 빈 화면 반환
        if (index == null || widget.songs.isEmpty || index >= widget.songs.length) {
          return const SizedBox.shrink();
        }

        final song = widget.songs[index];

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 상단 핸들 (BottomSheet 표시)
              Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 40),

              // 앨범 아트
              QueryArtworkWidget(
                key: ValueKey("detail_artwork_${song.id}"),
                id: song.id,
                type: ArtworkType.AUDIO,
                artworkWidth: double.infinity,
                artworkHeight: 300,
                artworkBorder: BorderRadius.circular(20),
                keepOldArtwork: true,
                artworkQuality: FilterQuality.high,
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

              // 제목 및 아티스트
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

              // 슬라이더 및 시간 표시 (핵심 최적화: StreamBuilder 분리)
              StreamBuilder<Duration>(
                stream: widget.player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = widget.player.duration ?? Duration.zero;

                  return Column(
                    children: [
                      Slider(
                        activeColor: const Color(0xFF1DB954),
                        inactiveColor: Colors.white24,
                        value: position.inSeconds.toDouble().clamp(
                            0, duration.inSeconds.toDouble()),
                        max: duration.inSeconds > 0
                            ? duration.inSeconds.toDouble()
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
                            Text(_formatDuration(position),
                                style: const TextStyle(color: Colors.grey)),
                            Text(_formatDuration(duration),
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // 컨트롤 바
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 반복 재생 버튼
                  StreamBuilder<LoopMode>(
                    stream: widget.player.loopModeStream,
                    builder: (context, snapshot) {
                      final loopMode = snapshot.data ?? LoopMode.off;
                      final isRepeatOne = loopMode == LoopMode.one;
                      return IconButton(
                        icon: Icon(
                          isRepeatOne ? Icons.repeat_one_on_rounded : Icons.repeat_rounded,
                          color: isRepeatOne ? const Color(0xFF1DB954) : Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          widget.player.setLoopMode(
                              isRepeatOne ? LoopMode.off : LoopMode.one);
                        },
                      );
                    },
                  ),

                  // 이전 곡
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 45, color: Colors.white),
                    onPressed: () => widget.player.seekToPrevious(),
                  ),

                  // 재생/일시정지
                  StreamBuilder<PlayerState>(
                    stream: widget.player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(
                          playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 80,
                          color: Colors.white,
                        ),
                        onPressed: () => playing ? widget.player.pause() : widget.player.play(),
                      );
                    },
                  ),

                  // 다음 곡
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 45, color: Colors.white),
                    onPressed: () => widget.player.seekToNext(),
                  ),

                  // 정지 및 닫기
                  IconButton(
                    icon: const Icon(Icons.stop, size: 35, color: Colors.white),
                    onPressed: () {
                      widget.player.stop();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}