import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';

import '../services/musicService.dart';
import '../services/audioManager.dart';
import '../services/storageService.dart';

import 'widget/HomeControlBar.dart';
import 'widget/SongListView.dart';
import 'widget/SongInfoDialog.dart';

class HomeScreen extends StatefulWidget {
  final List<SongModel> allSongs;
  final AudioManager audioManager;

  const HomeScreen({
    super.key,
    required this.allSongs,
    required this.audioManager,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicService _musicService = MusicService();
  final StorageService _storageService = StorageService();

  List<SongModel> displayedSongs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    displayedSongs = widget.allSongs;
    _searchController.addListener(_filterSongs);
    _setupStatusListeners();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allSongs != widget.allSongs) {
      setState(() {
        displayedSongs = widget.allSongs;
      });
    }
  }

  void _setupStatusListeners() {
    widget.audioManager.player.currentIndexStream.listen((index) {
      if (index != null && widget.allSongs.isNotEmpty) {
        if (index < widget.allSongs.length) {
          _storageService.saveLastStatus(widget.audioManager.player, widget.allSongs[index]);
        }
      }
    });
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      displayedSongs = widget.allSongs.where((song) {
        final title = song.title.toLowerCase();
        final artist = song.artist?.toLowerCase() ?? "unknown";
        return title.contains(query) || artist.contains(query);
      }).toList();
    });
  }

  // --- [수정된 부분] 에러가 발생하던 재생 로직 ---
  void _playMusic(int index) async {
    // 1. 현재 화면에 보이는 노래 선택
    final selectedSong = displayedSongs[index];

    // 2. 전체 리스트에서 해당 노래의 인덱스 찾기 (셔플/검색 대비)
    final originalIndex = widget.allSongs.indexWhere((s) => s.id == selectedSong.id);

    // 3. AudioManager에게 재생 명령 내리기
    // 이 부분이 핵심입니다!
    await widget.audioManager.playMusic(widget.allSongs, index: originalIndex);
  }

  // --- 다이얼로그 및 메뉴 로직 (기존 유지) ---
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
              leading: const Icon(Icons.playlist_add, color: Colors.orangeAccent),
              title: const Text("플레이리스트에 추가", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _showPlaylistSelector(song); },
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

  void _showPlaylistSelector(SongModel song) async {
    Map<String, List<int>> playlists = await _storageService.getPlaylists();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text("플레이리스트 선택", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add, color: Colors.greenAccent),
                title: const Text("새 플레이리스트 생성", style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _createNewPlaylist(song); },
              ),
              const Divider(color: Colors.grey),
              ...playlists.keys.map((name) => ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.white),
                title: Text(name, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  await _storageService.addSongToPlaylist(name, song.id);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name 에 추가되었습니다.")));
                },
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewPlaylist(SongModel song) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text("새 플레이리스트 이름", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "이름을 입력하세요", hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final playlists = await _storageService.getPlaylists();
                playlists[controller.text] = [song.id];
                await _storageService.savePlaylists(playlists);
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text("생성", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

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
              if (success && mounted) Navigator.pop(context);
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
              if (success && mounted) Navigator.pop(context);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopSearchBar(),
        HomeControlBar(
          songCount: displayedSongs.length,
          audioManager: widget.audioManager,
        ),
        Expanded(
          child: SongListView(
            songs: displayedSongs,
            onTap: _playMusic,
            onLongPress: _showSongMenu,
          ),
        ),
      ],
    );
  }

  Widget _buildTopSearchBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 15, right: 15),
      color: Colors.black,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12)
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "곡명, 아티스트 검색",
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}