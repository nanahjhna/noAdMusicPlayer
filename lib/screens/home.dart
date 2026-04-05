import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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
  SongModel? currentSong;
  bool isPlaying = false;
  bool isRepeatOne = false;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    requestPermission();

    _player.onPlayerComplete.listen((event) {
      if (isRepeatOne) {
        _player.seek(Duration.zero);
        _player.resume();
      } else {
        playNextSong();
      }
    });

    _player.onDurationChanged.listen((d) => setState(() => duration = d));
    _player.onPositionChanged.listen((p) => setState(() => position = p));
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => isPlaying = state == PlayerState.playing);
    });
  }

  Future<void> requestPermission() async {
    if (await Permission.audio.request().isGranted ||
        await Permission.storage.request().isGranted) {
      loadSongs();
    }
  }

  Future<void> loadSongs() async {
    final result = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    setState(() => songs = result);
  }

  Future<void> playMusic(SongModel song) async {
    await _player.stop();
    await _player.play(DeviceFileSource(song.data));
    setState(() => currentSong = song);
  }

  void playNextSong() {
    if (songs.isEmpty || currentSong == null) return;
    int currentIndex = songs.indexWhere((s) => s.id == currentSong!.id);
    int nextIndex = (currentIndex + 1) % songs.length;
    playMusic(songs[nextIndex]);
  }

  void playPreviousSong() {
    if (songs.isEmpty || currentSong == null) return;
    int currentIndex = songs.indexWhere((s) => s.id == currentSong!.id);
    int prevIndex = (currentIndex - 1 < 0) ? songs.length - 1 : currentIndex - 1;
    playMusic(songs[prevIndex]);
  }

  Future<void> togglePlay() async {
    isPlaying ? await _player.pause() : await _player.resume();
  }

  void toggleRepeat() => setState(() => isRepeatOne = !isRepeatOne);

  void _showPlayerDetail() {
    if (currentSong == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // StatefulBuilder의 setModalState는 모달 내부 UI만 다시 그리게 합니다.
        return StatefulBuilder(
          builder: (context, setModalState) {

            // 1. 노래 재생 위치(Position)가 바뀔 때마다 모달 UI 갱신
            // (이미 등록된 리스너가 있다면 중복되지 않게 주의하세요)
            _player.onPositionChanged.listen((p) {
              if (mounted) setModalState(() {});
            });

            return PlayerDetailScreen(
              // ⭐ 중요: 여기서 'currentSong'은 부모인 _HomeScreenState의 변수입니다.
              song: currentSong!,
              player: _player,
              isPlaying: isPlaying,
              isRepeatOne: isRepeatOne,
              duration: duration,
              position: position,
              onToggle: () {
                togglePlay();
                setModalState(() {}); // 재생 상태 변경 반영
              },
              onNext: () {
                playNextSong(); // 부모의 playNextSong 실행 (currentSong이 바뀜)
                setModalState(() {}); // ⭐ 바뀐 currentSong으로 모달 UI 갱신!
              },
              onPrev: () {
                playPreviousSong();
                setModalState(() {}); // ⭐ 바뀐 currentSong으로 모달 UI 갱신!
              },
              onRepeatToggle: () {
                toggleRepeat();
                setModalState(() {});
              },
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
        // 성능 최적화: 화면 밖 아이템을 미리 로드하여 깜빡임 감소
        cacheExtent: 1000,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongItem(
            key: ValueKey(song.id), // 고유 키 부여
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
                key: ValueKey("mini_${currentSong!.id}"), // 고유 키 추가
                id: currentSong!.id,
                type: ArtworkType.AUDIO,
                keepOldArtwork: true,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  currentSong!.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: playPreviousSong),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 35),
                onPressed: togglePlay,
              ),
              IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: playNextSong),
            ],
          ),
        ),
      )
          : null,
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}