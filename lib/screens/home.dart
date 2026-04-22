import 'dart:io'; // 1. 파일 최상단으로 이동
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

  List<SongModel> allSongs = [];
  List<SongModel> displayedSongs = [];
  ConcatenatingAudioSource? _playlist;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestPermission();
    _player.currentIndexStream.listen((_) => _saveLastStatus());
    _player.positionStream.listen((_) => _saveLastStatus());
    _searchController.addListener(_filterSongs);
  }

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

  // --- 추가된/수정된 기능들 ---

  // 1. 노래 이름 변경 다이얼로그
  Future<void> _renameSongDialog(SongModel song) async {
    TextEditingController renameController = TextEditingController(text: song.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text("곡 이름 변경", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: renameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              final file = File(song.data);
              if (await file.exists()) {
                final String dir = file.parent.path;
                final String extension = file.path.split('.').last;
                final String newPath = "$dir/${renameController.text}.$extension";

                try {
                  await file.rename(newPath);
                  if (mounted) Navigator.pop(context);
                  loadSongs(); // 목록 새로고침
                } catch (e) {
                  _showErrorSnackBar("이름 변경 실패: 권한이 없거나 파일이 사용 중입니다.");
                }
              }
            },
            child: const Text("변경", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  // 2. 노래 삭제 다이얼로그
  Future<void> _deleteSongDialog(SongModel song) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text("곡 삭제", style: TextStyle(color: Colors.white)),
        content: const Text("정말로 이 곡을 기기에서 삭제하시겠습니까?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              try {
                final file = File(song.data);
                if (await file.exists()) {
                  await file.delete();
                  if (mounted) Navigator.pop(context);
                  loadSongs(); // 목록 새로고침
                }
              } catch (e) {
                _showErrorSnackBar("삭제 실패: 시스템에서 파일 수정을 거부했습니다.");
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // 3. 롱탭 메뉴 (추후 기능 확장 용이)
  void _showSongMenu(SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(song.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text("이름 변경", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _renameSongDialog(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteSongDialog(song);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 에러 메시지 표시용
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- 기존 로직 (상태 저장/복구/권한/재생 등) ---

  Future<void> _saveLastStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final index = _player.currentIndex;
    if (index != null && allSongs.isNotEmpty) {
      await prefs.setInt('last_index', index);
      await prefs.setInt('last_position', _player.position.inMilliseconds);
      await prefs.setInt('last_song_id', allSongs[index].id);
    }
  }

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
      allSongs = result;
      displayedSongs = result;
    });

    if (_playlist != null) {
      await _restoreLastStatus();
    }
  }

  Future<void> playMusic(int index) async {
    try {
      if (_playlist == null) return;
      final selectedSongId = displayedSongs[index].id;
      final originalIndex = allSongs.indexWhere((s) => s.id == selectedSongId);
      await _player.seek(Duration.zero, index: originalIndex);
      _player.play();
    } catch (e) {
      debugPrint("재생 에러: $e");
    }
  }

  void _toggleShuffle() async {
    final isShuffle = _player.shuffleModeEnabled;
    await _player.setShuffleModeEnabled(!isShuffle);
    if (!isShuffle) await _player.shuffle();
  }

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
    setState(() {});
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
          _buildPlayControlsBar(),
          Expanded(
            child: displayedSongs.isEmpty
                ? const Center(child: Text("곡이 없거나 로딩 중입니다.", style: TextStyle(color: Colors.white)))
                : ListView.builder(
              cacheExtent: 500,
              itemCount: displayedSongs.length,
              itemBuilder: (context, index) {
                final song = displayedSongs[index];
                return SongItem(
                  key: ValueKey(song.id),
                  song: song,
                  onTap: () => playMusic(index),
                  onLongPress: () => _showSongMenu(song), // 👈 롱탭 연결됨
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

  Widget _buildPlayControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("총 ${displayedSongs.length}곡", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Row(
            children: [
              StreamBuilder<bool>(
                stream: _player.shuffleModeEnabledStream,
                builder: (context, snapshot) {
                  final enabled = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(Icons.shuffle, color: enabled ? Colors.greenAccent : Colors.white, size: 20),
                    onPressed: _toggleShuffle,
                  );
                },
              ),
              StreamBuilder<LoopMode>(
                stream: _player.loopModeStream,
                builder: (context, snapshot) {
                  final mode = snapshot.data ?? LoopMode.off;
                  IconData icon = (mode == LoopMode.one) ? Icons.repeat_one : Icons.repeat;
                  Color color = (mode == LoopMode.off) ? Colors.white : Colors.greenAccent;
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
                  decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
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
                  Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text(song.artist ?? "Unknown", style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: () => _player.seekToPrevious()),
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
            IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: () => _player.seekToNext()),
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