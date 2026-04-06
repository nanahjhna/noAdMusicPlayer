import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongItem extends StatelessWidget {
  // 1. StatelessWidget으로 변경
  final SongModel song;
  final VoidCallback onTap;

  const SongItem({
    super.key,
    required this.song,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // 2. 고정된 높이 제공 (레이아웃 계산 속도 향상)
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 50,
        height: 50,
        child: QueryArtworkWidget(
          key: ValueKey("list_art_${song.id}"),
          // 3. 고유 키 부여
          id: song.id,
          type: ArtworkType.AUDIO,
          keepOldArtwork: true,
          format: ArtworkFormat.JPEG,
          artworkQuality: FilterQuality.low,
          // 4. 리스트용 저화질 설정
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
      onTap: onTap,
    );
  }
}