import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../services/musicService.dart';
import '../services/audioManager.dart';
import '../services/storageService.dart';

import 'widget/playerDetailScreen.dart';
import 'widget/miniPlayer.dart';
import 'widget/HomeControlBar.dart';
import 'widget/SongListView.dart';
import 'widget/SongInfoDialog.dart';

class HomeScreen extends StatefulWidget {
  // MainHolder로부터 데이터를 전달받습니다.
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
    // 부모로부터 받은 곡 목록을 초기화합니다.
    displayedSongs = widget.allSongs;
    _searchController.addListener(_filterSongs);

    // 앱 상태 리스너 설정 (기존 소스 유지)
    _setupStatusListeners();
  }

  // 부모 위젯(MainHolder)의 데이터가 업데이트될 때 호출됩니다.
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
        // 인덱스 범위 초과 방지 체크 추가
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

  void _playMusic(int index) async {
    // displayedSongs에서 선택된 곡의 실제 ID를 찾습니다.
    final selectedId = displayedSongs[index].id;
    // 전체 목록(allSongs)에서의 위치를 찾습니다.
    final originalIndex = widget.allSongs.indexWhere((s) => s.id == selectedId);

    // 전체 목록으로 플레이리스트 설정 및 재생
    final playlist = widget.audioManager.createPlaylist(widget.allSongs);
    await widget.audioManager.player.setAudioSource(
      playlist,
      initialIndex: originalIndex,
    );
    widget.audioManager.player.play();
  }

  // --- 메뉴 및 다이얼로그 로직 (기존 소스 유지) ---

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
              onTap: () {
                Navigator.pop(context);
                _showPlaylistSelector(song);
              },
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
                onTap: () {
                  Navigator.pop(context);
                  _createNewPlaylist(song);
                },
              ),
              const Divider(color: Colors.grey),
              ...playlists.keys.map((name) => ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.white),
                title: Text(name, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  await _storageService.addSongToPlaylist(name, song.id);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$name 에 추가되었습니다."))
                  );
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
              if (success && mounted) {
                Navigator.pop(context);
                // 곡 삭제/변경 후 데이터 갱신은 부모(MainHolder)에서 처리하는 것이 좋으나,
                // 여기서는 기존 로직대로 필요시 처리합니다.
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
    // Scaffold를 제거하고 Column으로 시작하여 MainHolder의 네비게이션 바가 보이게 합니다.
    return Column(
      children: [
        // AppBar 대신 사용할 상단 검색바 영역
        _buildTopSearchBar(),

        HomeControlBar(
            songCount: displayedSongs.length,
            audioManager: widget.audioManager
        ),

        Expanded(
          child: SongListView(
            songs: displayedSongs,
            onTap: _playMusic,
            onLongPress: _showSongMenu,
          ),
        ),

        // 미니플레이어 영역 (MainHolder 하단 바 위에 배치)
        _buildMiniPlayerSection(),
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

  Widget _buildMiniPlayerSection() {
    return StreamBuilder<int?>(
      stream: widget.audioManager.player.currentIndexStream,
      builder: (context, snapshot) {
        final index = snapshot.data;
        if (index == null || widget.allSongs.isEmpty) return const SizedBox.shrink();

        // 인덱스 안전 처리
        if (index >= widget.allSongs.length) return const SizedBox.shrink();

        return MiniPlayer(
          song: widget.allSongs[index],
          player: widget.audioManager.player,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PlayerDetailScreen(
                player: widget.audioManager.player,
                songs: widget.allSongs
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    // 플레이어 해제는 전역 관리 주체인 AudioManager 또는 MainHolder에서 수행하는 것이 안전하므로 제거합니다.
    super.dispose();
  }
}