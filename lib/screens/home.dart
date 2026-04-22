import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // 데이터 관리용 리스트
  List<SongModel> allSongs = []; // 기기의 모든 곡
  List<SongModel> displayedSongs = []; // 검색 결과로 보여줄 곡
  ConcatenatingAudioSource? _playlist;

  // 검색 제어용 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestPermission();

    // 🚀 상태 저장 리스너
    _player.currentIndexStream.listen((_) => _saveLastStatus());
    _player.positionStream.listen((_) => _saveLastStatus());

    // 🚀 검색 리스너 등록
    _searchController.addListener(_filterSongs);
  }

  // 검색 필터링 로직
  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      displayedSongs = allSongs.where((song) {
        final title = song.title.toLowerCase();
        final artist = song.artist?.toLowerCase() ?? "unknown";
        return title.contains(query) || artist.contains(query);
      }).toList();
    });
  }

  // 마지막 상태 저장 (SharedPreferences)
  Future<void> _saveLastStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final index = _player.currentIndex;
    if (index != null && allSongs.isNotEmpty) {
      await prefs.setInt('last_index', index);
      await prefs.setInt('last_position', _player.position.inMilliseconds);
      await prefs.setInt('last_song_id', allSongs[index].id);
    }
  }

  // 마지막 상태 복구
  Future<void> _restoreLastStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIndex = prefs.getInt('last_index');
    final lastPosition = prefs.getInt('last_position') ?? 0;
    final lastSongId = prefs.getInt('last_song_id');

    if (lastIndex != null && lastIndex < allSongs.length) {
      if (allSongs[lastIndex].id == lastSongId) {
        await _player.setAudioSource(_playlist!,
            initialIndex: lastIndex,
            initialPosition: Duration(milliseconds: lastPosition));
      } else {
        await _player.setAudioSource(_playlist!);
      }
    } else {
      await _player.setAudioSource(_playlist!);
    }
  }

  // 권한 요청
  Future<void> requestPermission() async {
    final status = await Permission.audio.request();
    if (status.isGranted) {
      loadSongs();
    } else {
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) loadSongs();
    }
  }

  // 곡 로드 및 플레이리스트 생성
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
      allSongs = result;
      displayedSongs = result;
    });

    if (_playlist != null) {
      await _restoreLastStatus();
    }
  }

  // 음악 재생 (검색된 인덱스를 실제 인덱스로 변환)
  Future<void> playMusic(int index) async {
    try {
      if (_playlist == null) return;

      // 검색된 리스트의 곡 ID를 전체 리스트에서 찾아 인덱스 확보
      final selectedSongId = displayedSongs[index].id;
      final originalIndex = allSongs.indexWhere((s) => s.id == selectedSongId);

      await _player.seek(Duration.zero, index: originalIndex);
      _player.play();
    } catch (e) {
      debugPrint("재생 에러: $e");
    }
  }

  // 재생 모드 변경: 랜덤(Shuffle)
  void _toggleShuffle() async {
    final isShuffle = _player.shuffleModeEnabled;
    await _player.setShuffleModeEnabled(!isShuffle);
    if (!isShuffle) await _player.shuffle();
  }

  // 재생 모드 변경: 반복(Loop)
  void _toggleLoopMode() async {
    LoopMode nextMode;
    if (_player.loopMode == LoopMode.off) {
      nextMode = LoopMode.all;
    } else if (_player.loopMode == LoopMode.all) {
      nextMode = LoopMode.one;
    } else {
      nextMode = LoopMode.off;
    }
    await _player.setLoopMode(nextMode);
    setState(() {}); // 아이콘 상태 반영
  }

  void _showPlayerDetail() {
    if (allSongs.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerDetailScreen(
        player: _player,
        songs: allSongs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // 🚀 검색바가 포함된 타이틀
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "곡명, 아티스트 검색",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 🚀 재생 모드 설정 상단 바
          _buildPlayControlsBar(),

          Expanded(
            child: displayedSongs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              cacheExtent: 500,
              itemCount: displayedSongs.length,
              itemBuilder: (context, index) {
                final song = displayedSongs[index];
                return SongItem(
                  key: ValueKey(song.id),
                  song: song,
                  onTap: () => playMusic(index),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int?>(
        stream: _player.currentIndexStream,
        builder: (context, snapshot) {
          final index = snapshot.data;
          if (index == null || allSongs.isEmpty || index >= allSongs.length) {
            return const SizedBox.shrink();
          }
          return _buildMiniPlayer(allSongs[index]);
        },
      ),
    );
  }

  // 재생 모드 버튼들 (셔플, 반복)
  Widget _buildPlayControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "총 ${displayedSongs.length}곡",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Row(
            children: [
              // 셔플 버튼
              StreamBuilder<bool>(
                stream: _player.shuffleModeEnabledStream,
                builder: (context, snapshot) {
                  final enabled = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(Icons.shuffle,
                        color: enabled ? Colors.greenAccent : Colors.white, size: 20),
                    onPressed: _toggleShuffle,
                  );
                },
              ),
              // 반복 버튼
              StreamBuilder<LoopMode>(
                stream: _player.loopModeStream,
                builder: (context, snapshot) {
                  final mode = snapshot.data ?? LoopMode.off;
                  IconData icon = Icons.repeat;
                  Color color = Colors.white;
                  if (mode == LoopMode.one) {
                    icon = Icons.repeat_one;
                    color = Colors.greenAccent;
                  } else if (mode == LoopMode.all) {
                    color = Colors.greenAccent;
                  }
                  return IconButton(
                    icon: Icon(icon, color: color, size: 20),
                    onPressed: _toggleLoopMode,
                  );
                },
              ),
            ],
          )
        ],
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
          color: Colors.black.withOpacity(0.95),
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
                nullArtworkWidget: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    _searchController.dispose();
    _player.dispose();
    super.dispose();
  }
}