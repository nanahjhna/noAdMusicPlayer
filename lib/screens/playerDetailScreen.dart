import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerDetailScreen extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 상단 드래그 핸들
          Container(
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 40),

          // 💿 앨범 아트 (깜빡임 방지 최적화)
          QueryArtworkWidget(
            // 고유 키를 부여하여 Slider 업데이트 시 위젯이 파괴/재생성되는 것을 방지
            key: ValueKey("artwork_${song.id}"),
            id: song.id,
            type: ArtworkType.AUDIO,
            artworkWidth: double.infinity,
            artworkHeight: 300,
            artworkBorder: BorderRadius.circular(20),
            keepOldArtwork: true, // 로딩 중 이전 이미지 유지
            format: ArtworkFormat.JPEG, // 로딩 속도 최적화
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

          // 곡 정보
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

          // 🛠 재생바 (Slider)
          Slider(
            activeColor: const Color(0xFF1DB954), // Spotify 스타일 그린
            inactiveColor: Colors.white24,
            value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
            max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
            onChanged: (value) async {
              await player.seek(Duration(seconds: value.toInt()));
            },
          ),

          // 시간 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position), style: const TextStyle(color: Colors.grey)),
                Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 🕹 컨트롤러 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 반복 모드 버튼
              IconButton(
                icon: Icon(
                  isRepeatOne ? Icons.repeat_one_on_rounded : Icons.repeat_rounded,
                  color: isRepeatOne ? const Color(0xFF1DB954) : Colors.white,
                  size: 30,
                ),
                onPressed: onRepeatToggle,
              ),

              // 이전 곡
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 45, color: Colors.white),
                onPressed: onPrev,
              ),

              // 재생/일시정지
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 80,
                  color: Colors.white,
                ),
                onPressed: onToggle,
              ),

              // 다음 곡
              IconButton(
                icon: const Icon(Icons.skip_next, size: 45, color: Colors.white),
                onPressed: onNext,
              ),

              // 레이아웃 균형을 위한 더미 공간 (나중에 셔플 버튼 등을 넣을 수 있음)
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 시간 포맷팅 함수 (00:00)
  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}