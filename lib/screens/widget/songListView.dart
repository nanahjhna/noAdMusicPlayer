import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'songItem.dart';

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
    if (songs.isEmpty) {
      return const Center(
        child: Text("곡이 없거나 로딩 중입니다.", style: TextStyle(color: Colors.white)),
      );
    }
    return ListView.builder(
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