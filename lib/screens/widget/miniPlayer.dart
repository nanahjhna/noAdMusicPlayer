import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MiniPlayer extends StatelessWidget {
  final SongModel song;
  final AudioPlayer player;
  final VoidCallback onTap;
  final VoidCallback onClose; // 닫기 기능을 위한 콜백 추가

  const MiniPlayer({
    super.key,
    required this.song,
    required this.player,
    required this.onTap,
    required this.onClose, // 필수 인자로 설정
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12), // 버튼 공간 확보를 위해 패딩 살짝 조정
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            // 1. 앨범 아트
            SizedBox(
              width: 50,
              height: 50,
              child: QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                artworkBorder: BorderRadius.circular(8),
                nullArtworkWidget: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. 곡 정보
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist ?? "Unknown",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 3. 컨트롤 버튼들 (이전, 재생, 다음)
            IconButton(
              constraints: const BoxConstraints(), // 터치 영역 최적화
              icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
              onPressed: () => player.seekToPrevious(),
            ),
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return IconButton(
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => playing ? player.pause() : player.play(),
                );
              },
            ),
            IconButton(
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
              onPressed: () => player.seekToNext(),
            ),

            // 4. 구분선 (선택 사항: 버튼들 사이를 시각적으로 분리)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: VerticalDivider(color: Colors.white10, indent: 25, endIndent: 25),
            ),

            // 5. 닫기(X) 버튼
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: onClose, // 외부에서 넘겨받은 닫기 로직 실행
            ),
          ],
        ),
      ),
    );
  }
}