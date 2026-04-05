import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

// --- 📄 파일 하단이나 별도 파일에 추가 ---
class SongItem extends StatefulWidget {
  final SongModel song;
  final VoidCallback onTap;

  const SongItem({super.key, required this.song, required this.onTap});

  @override
  State<SongItem> createState() => _SongItemState();
}

class _SongItemState extends State<SongItem> with AutomaticKeepAliveClientMixin {
  // 화면에서 사라져도 상태를 유지하여 다시 그릴 때 깜빡임을 방지함
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mixin 사용 시 필수
    return ListTile(
      leading: QueryArtworkWidget(
        id: widget.song.id,
        type: ArtworkType.AUDIO,
        // 구버전/신버전 호환을 위해 가능한 최적화 옵션 추가
        keepOldArtwork: true,
        format: ArtworkFormat.JPEG,
        nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
      ),
      title: Text(
        widget.song.title,
        style: const TextStyle(color: Colors.white, overflow: TextOverflow.ellipsis),
      ),
      subtitle: Text(
        widget.song.artist ?? "Unknown Artist",
        style: const TextStyle(color: Colors.grey, overflow: TextOverflow.ellipsis),
      ),
      onTap: widget.onTap,
    );
  }
}