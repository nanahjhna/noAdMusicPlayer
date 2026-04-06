import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // 수정됨
import 'package:just_audio_background/just_audio_background.dart'; // 추가됨
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
  // 1. 선언부 통합 (just_audio 사용)
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<SongModel> songs = [];
  SongModel? currentSong;
  bool isPlaying = false;
  bool isRepeatOne = false;
  bool isPlaylistSet = false;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    requestPermission();

    // 2. just_audio 스트림 리스너 설정
    // 재생 상태 및 완료 리스너
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });
      }
    });

    // 재생 위치 리스너
    _player.positionStream.listen((p) {
      if (mounted) setState(() => position = p);
    });

    // 곡 길이 리스너
    _player.durationStream.listen((d) {
      if (mounted) setState(() => duration = d ?? Duration.zero);
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && mounted && index < songs.length) {
        setState(() {
          currentSong = songs[index];
        });
      }
    });
  }

  Future<void> requestPermission() async {
    if (await Permission.audio
        .request()
        .isGranted) {
      loadSongs();
    } else if (await Permission.storage
        .request()
        .isGranted) {
      loadSongs();
    }
  }

  Future<void> loadSongs() async {
    final result = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    setState(() {
      songs = result;
      isPlaylistSet = false; // 🔥 playlist 재생성용

      // 🔥 추가 (UX 개선)
      if (songs.isNotEmpty && currentSong == null) {
        currentSong = songs[0];
      }
    });
  }

  // 3. 재생 함수 수정 (알림창 컨트롤 활성화 버전)
  // 🚀 알림창 컨트롤(이전/다음/종료) 활성화를 위한 재생 함수
  Future<void> playMusic(SongModel song) async {
    try {
      int index = songs.indexOf(song);

      if (!isPlaylistSet) {
        final playlist = ConcatenatingAudioSource(
          children: songs.map((s) {
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

        await _player.setAudioSource(playlist);
        isPlaylistSet = true;
      }

      // ⭐ 핵심: 먼저 currentSong 반영
      setState(() {
        currentSong = song;
      });

      await _player.seek(Duration.zero, index: index);
      await _player.play();
    } catch (e) {
      debugPrint("에러: $e");
    }
  }

  void playNextSong() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  void playPreviousSong() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero, index: songs.length - 1);
    }
  }

  void stopMusic() async {
    await _player.stop();
  }

  Future<void> togglePlay() async {
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void toggleRepeat() {
    setState(() {
      isRepeatOne = !isRepeatOne;
      // just_audio 자체 반복 모드 설정 (선택 사항)
      _player.setLoopMode(isRepeatOne ? LoopMode.one : LoopMode.off);
    });
  }

  void _showPlayerDetail() {
    if (currentSong == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StreamBuilder<int?>(
          stream: _player.currentIndexStream, // 🔥 핵심
          builder: (context, snapshot) {
            final index = snapshot.data ?? 0;

            if (songs.isEmpty || index >= songs.length) {
              return const SizedBox();
            }

            final song = songs[index]; // 🔥 항상 최신 곡

            return PlayerDetailScreen(
              song: song, // 🔥 currentSong 대신 이걸 사용
              player: _player,
              isPlaying: isPlaying,
              isRepeatOne: isRepeatOne,
              duration: duration,
              position: position,
              onToggle: togglePlay,
              onNext: playNextSong,
              onPrev: playPreviousSong,
              onRepeatToggle: toggleRepeat,
              onStop: stopMusic,
            );
          },
        );
      },
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
        cacheExtent: 1000,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongItem(
            key: ValueKey(song.id),
            song: song,
            onTap: () => playMusic(song),
          );
        },
      ),
      bottomNavigationBar: currentSong != null
          ? GestureDetector(
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
              QueryArtworkWidget(
                key: ValueKey("mini_${currentSong!.id}"),
                id: currentSong!.id,
                type: ArtworkType.AUDIO,
                keepOldArtwork: false,
                artworkQuality: FilterQuality.low,
                // 추가
                nullArtworkWidget: const Icon(
                    Icons.music_note, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  currentSong!.title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: playPreviousSong,
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 35,
                ),
                onPressed: togglePlay,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: playNextSong,
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }
}