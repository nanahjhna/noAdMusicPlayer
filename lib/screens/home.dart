import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'playerDetailScreen.dart';
import 'songItem.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<SongModel> songs = [];
  ConcatenatingAudioSource? _playlist;

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    final status = await Permission.audio.request();
    if (status.isGranted) {
      loadSongs();
    } else {
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) loadSongs();
    }
  }

  Future<void> loadSongs() async {
    final result = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    _playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: result.map((s) {
        return AudioSource.uri(
          Uri.parse(s.data),
          tag: MediaItem(
            id: '${s.id}',
            title: s.title,
            artist: s.artist ?? "Unknown",
            album: s.album ?? "Unknown",
            duration: Duration(milliseconds: s.duration ?? 0),
          ),
        );
      }).toList(),
    );

    setState(() {
      songs = result;
    });
  }

  Future<void> playMusic(int index) async {
    try {
      if (_playlist == null) return;

      if (_player.audioSource == null) {
        await _player.setAudioSource(_playlist!);
      }

      await _player.seek(Duration.zero, index: index);
      _player.play();
    } catch (e) {
      debugPrint("재생 에러: $e");
    }
  }

  void _showPlayerDetail() {
    if (songs.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerDetailScreen(
        player: _player,
        songs: songs, // 이 부분이 에러가 난다면 PlayerDetailScreen 생성자를 확인해야 합니다.
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("No Ad Music Player"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        cacheExtent: 500,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongItem(
            key: ValueKey(song.id),
            song: song,
            onTap: () => playMusic(index),
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<int?>(
        stream: _player.currentIndexStream,
        builder: (context, snapshot) {
          final index = snapshot.data;
          if (index == null || songs.isEmpty || index >= songs.length) {
            return const SizedBox.shrink();
          }

          final currentSong = songs[index];
          return _buildMiniPlayer(currentSong);
        },
      ),
    );
  }

  Widget _buildMiniPlayer(SongModel song) {
    return GestureDetector(
      onTap: _showPlayerDetail,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: QueryArtworkWidget(
                key: ValueKey("mini_${song.id}"),
                id: song.id,
                type: ArtworkType.AUDIO,
                artworkBorder: BorderRadius.circular(8),
                artworkQuality: FilterQuality.low,
                keepOldArtwork: true,
                // [에러 수정] nullArtworkWidget에서 const를 제거했습니다.
                nullArtworkWidget: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                song.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              onPressed: () => _player.seekToPrevious(),
            ),
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 35),
                  onPressed: () => playing ? _player.pause() : _player.play(),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              onPressed: () => _player.seekToNext(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}