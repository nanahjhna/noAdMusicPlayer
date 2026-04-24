import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/musicService.dart';
import '../services/audioManager.dart';
import '../services/storageService.dart';

import 'playerDetailScreen.dart';
import 'miniPlayer.dart';
import 'HomeControlBar.dart';
import 'SongListView.dart';
import 'SongInfoDialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<void> _initApp() async {
    final status = await Permission.audio.request();
    if (status.isGranted) {
      await _loadSongs();
      _setupStatusListeners();
    }
  }

  void _setupStatusListeners() {
    _audioManager.player.currentIndexStream.listen((index) {
      if (index != null && allSongs.isNotEmpty) {
        _storageService.saveLastStatus(_audioManager.player, allSongs[index]);
      }
    });
  }

  Future<void> _loadSongs() async {
    final songs = await _musicService.fetchSongs();
    if (songs.isNotEmpty) {
      final playlist = _audioManager.createPlaylist(songs);

      // 1. 기존 로직: 마지막 재생 곡 상태(인덱스, 위치) 복구
      final lastStatus = await _storageService.restoreLastStatus(songs);

      // 2. 추가 로직: 마지막 재생 모드(셔플, 반복) 설정값 불러오기
      final savedMode = await _storageService.restorePlayMode();

      // 3. 플레이어 설정 적용 (기존 소스 + 모드 설정)
      await _audioManager.player.setAudioSource(
        playlist,
        initialIndex: lastStatus['index'],
        initialPosition: lastStatus['position'],
      );

      // 불러온 셔플 및 반복 모드 적용
      await _audioManager.player.setShuffleModeEnabled(savedMode['isShuffle']);
      await _audioManager.player.setLoopMode(savedMode['loopMode']);

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

  void _playMusic(int index) async {
    final selectedId = displayedSongs[index].id;
    final originalIndex = allSongs.indexWhere((s) => s.id == selectedId);
    await _audioManager.player.seek(Duration.zero, index: originalIndex);
    _audioManager.player.play();
  }

  // --- 메뉴 및 다이얼로그 로직 ---

  void _showSongMenu(SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text("이름 변경", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _showRenameDialog(song); },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
              onTap: () { Navigator.pop(context); _showDeleteDialog(song); },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
              title: const Text("파일 정보", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); showDialog(context: context, builder: (_) => SongInfoDialog(song: song)); },
            ),
          ],
        ),
      ),
    );
  }

  // 이름 변경 다이얼로그 (복구됨)
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
                _loadSongs();
              }
            },
            child: const Text("변경", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  // 삭제 다이얼로그 (복구됨)
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
      appBar: AppBar(
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
      ),
      body: Column(
        children: [
          HomeControlBar(songCount: displayedSongs.length, audioManager: _audioManager),
          Expanded(
            child: SongListView(
              songs: displayedSongs,
              onTap: _playMusic,
              onLongPress: _showSongMenu,
            ),
          ),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int?>(
        stream: _audioManager.player.currentIndexStream,
        builder: (context, snapshot) {
          final index = snapshot.data;
          if (index == null || allSongs.isEmpty) return const SizedBox.shrink();
          return MiniPlayer(
            song: allSongs[index],
            player: _audioManager.player,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => PlayerDetailScreen(player: _audioManager.player, songs: allSongs),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioManager.player.dispose();
    super.dispose();
  }
}