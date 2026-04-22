import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongItem extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; // 1. 롱클릭 콜백 파라미터 추가

  const SongItem({
    super.key,
    required this.song,
    required this.onTap,
    this.onLongPress, // 2. 생성자에 추가 (선택사항이므로 required는 제외)
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // 리스트 레이아웃 최적화
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

      // 3. ListTile의 기능을 연결
      onTap: onTap,
      onLongPress: onLongPress,

      leading: SizedBox(
        width: 50,
        height: 50,
        child: QueryArtworkWidget(
          key: ValueKey("list_art_${song.id}"),
          id: song.id,
          type: ArtworkType.AUDIO,
          keepOldArtwork: true,
          format: ArtworkFormat.JPEG,
          artworkQuality: FilterQuality.low, // 리스트 성능을 위해 저화질 사용
          artworkBorder: BorderRadius.circular(8),
          nullArtworkWidget: Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note, color: Colors.white70),
          ),
        ),
      ),
      title: Text(
        song.title,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            overflow: TextOverflow.ellipsis
        ),
      ),
      subtitle: Text(
        song.artist ?? "Unknown Artist",
        style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            overflow: TextOverflow.ellipsis
        ),
      ),
    );
  }
}