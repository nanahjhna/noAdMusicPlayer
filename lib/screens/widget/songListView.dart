import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'songItem.dart';
import '../../app_strings.dart'; // [추가] 다국어 클래스 임포트

class SongListView extends StatelessWidget {
  final List<SongModel> songs;
  final Function(int) onTap;
  final Function(SongModel) onLongPress;

  const SongListView({
    super.key,
    required this.songs,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // [추가] 다국어 객체 가져오기
    final strings = AppStrings.of(context);

    if (songs.isEmpty) {
      return Center(
        // [변경] 하드코딩된 한국어를 다국어 변수로 교체
        child: Text(
          strings.noSongsFound,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      // 성능 최적화를 위해 padding 추가 가능
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return SongItem(
          key: ValueKey(song.id),
          song: song,
          onTap: () => onTap(index),
          onLongPress: () => onLongPress(song),
        );
      },
    );
  }
}