import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/musicService.dart';
import '../services/audioManager.dart';
import '../services/storageService.dart';
import 'playerDetailScreen.dart';
import 'songItem.dart';
import 'miniPlayer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 서비스 인스턴스 초기화
  final MusicService _musicService = MusicService();
  final AudioManager _audioManager = AudioManager();
  final StorageService _storageService = StorageService();

  List<SongModel> allSongs = [];
  List<SongModel> displayedSongs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initApp();
    _searchController.addListener(_filterSongs);
  }

  // 앱 초기화 및 권한 확인
  Future<void> _initApp() async {
    final status = await Permission.audio.request();
    if (status.isGranted) {
      await _loadSongs();
      _setupStatusListeners();
    }
  }

  // 상태 저장 리스너 설정
  void _setupStatusListeners() {
    _audioManager.player.currentIndexStream.listen((index) {
      if (index != null && allSongs.isNotEmpty) {
        _storageService.saveLastStatus(_audioManager.player, allSongs[index]);
      }
    });
  }

  // 곡 로드 및 초기 위치 복구
  Future<void> _loadSongs() async {
    final songs = await _musicService.fetchSongs();
    if (songs.isNotEmpty) {
      final playlist = _audioManager.createPlaylist(songs);

      // 마지막 상태 복구
      final lastStatus = await _storageService.restoreLastStatus(songs);
      await _audioManager.player.setAudioSource(
        playlist,
        initialIndex: lastStatus['index'],
        initialPosition: lastStatus['position'],
      );

      setState(() {
        allSongs = songs;
        displayedSongs = songs;
      });
    }
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

  // --- UI 핸들러 ---

  void _playMusic(int index) async {
    final selectedId = displayedSongs[index].id;
    final originalIndex = allSongs.indexWhere((s) => s.id == selectedId);
    await _audioManager.player.seek(Duration.zero, index: originalIndex);
    _audioManager.player.play();
  }

  void _showSongMenu(SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuHeader(song.title),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text("이름 변경", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(song);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 다이얼로그 (Service 호출) ---

  Future<void> _showRenameDialog(SongModel song) async {
    TextEditingController renameController = TextEditingController(text: song.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text("곡 이름 변경", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: renameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              bool success = await _musicService.renameFile(song.data, renameController.text);
              if (success && mounted) {
                Navigator.pop(context);
                _loadSongs(); // 목록 새로고침
              }
            },
            child: const Text("변경", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(SongModel song) async {
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
              bool success = await _musicService.deleteFile(song.data);
              if (success && mounted) {
                Navigator.pop(context);
                _loadSongs();
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildControlBar(),
          Expanded(child: _buildSongList()),
        ],
      ),
      bottomNavigationBar: _buildMiniPlayerContainer(),
    );
  }

  // --- 소형 위젯 빌더들 ---

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      title: Container(
        height: 40,
        decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(10)),
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
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("총 ${displayedSongs.length}곡", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Row(
            children: [
              IconButton(
                icon: StreamBuilder<bool>(
                  stream: _audioManager.player.shuffleModeEnabledStream,
                  builder: (context, snapshot) => Icon(Icons.shuffle,
                      color: (snapshot.data ?? false) ? Colors.greenAccent : Colors.white, size: 20),
                ),
                onPressed: () => _audioManager.toggleShuffle(),
              ),
              IconButton(
                icon: StreamBuilder<LoopMode>(
                  stream: _audioManager.player.loopModeStream,
                  builder: (context, snapshot) {
                    final mode = snapshot.data ?? LoopMode.off;
                    return Icon(mode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                        color: mode == LoopMode.off ? Colors.white : Colors.greenAccent, size: 20);
                  },
                ),
                onPressed: () => _audioManager.toggleLoopMode(),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSongList() {
    if (displayedSongs.isEmpty) {
      return const Center(child: Text("곡이 없거나 로딩 중입니다.", style: TextStyle(color: Colors.white)));
    }
    return ListView.builder(
      itemCount: displayedSongs.length,
      itemBuilder: (context, index) {
        final song = displayedSongs[index];
        return SongItem(
          key: ValueKey(song.id),
          song: song,
          onTap: () => _playMusic(index),
          onLongPress: () => _showSongMenu(song),
        );
      },
    );
  }

  Widget? _buildMiniPlayerContainer() {
    return StreamBuilder<int?>(
      stream: _audioManager.player.currentIndexStream,
      builder: (context, snapshot) {
        final index = snapshot.data;
        if (index == null || allSongs.isEmpty) return const SizedBox.shrink();

        return MiniPlayer(
          song: allSongs[index],
          player: _audioManager.player,
          onTap: () => _showPlayerDetail(),
        );
      },
    );
  }

  void _showPlayerDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerDetailScreen(player: _audioManager.player, songs: allSongs),
    );
  }

  Widget _buildMenuHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioManager.player.dispose();
    super.dispose();
  }
}