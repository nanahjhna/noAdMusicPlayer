import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';

import '../services/musicService.dart';
import '../services/audioManager.dart';
import '../services/storageService.dart';

import 'widget/HomeControlBar.dart';
import 'widget/SongListView.dart';
import 'widget/SongInfoDialog.dart';

import '../app_strings.dart';

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

    // 1. 허용할 확장자 리스트 정의
    final allowedFormats = ['mp3', 'm4a', 'flac', 'wav', 'ogg'];

    // 2. 전체 곡에서 해당 확장자를 가진 곡만 추출하여 일람 구성
    displayedSongs = widget.allSongs.where((song) {
      // 확장자를 소문자로 변환하여 비교 (대문자 MP3 등 대비)
      final ext = song.fileExtension.toLowerCase();
      return allowedFormats.contains(ext);
    }).toList();

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
        // 'unknown' -> 다국어 처리
        final artist = song.artist?.toLowerCase() ?? AppStrings.of(context).unknownArtist;
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
    final strings = AppStrings.of(context); // 텍스트 객체 가져오기

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
              title: Text(strings.rename, style: const TextStyle(color: Colors.white)), // "이름 변경"
              onTap: () { Navigator.pop(context); _showRenameDialog(song); },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.orangeAccent),
              title: Text(strings.addToPlaylist, style: const TextStyle(color: Colors.white)), // "플레이리스트에 추가"
              onTap: () { Navigator.pop(context); _showPlaylistSelector(song); },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: Text(strings.delete, style: const TextStyle(color: Colors.redAccent)), // "삭제"
              onTap: () { Navigator.pop(context); _showDeleteDialog(song); },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
              title: Text(strings.fileInfo, style: const TextStyle(color: Colors.white)), // "파일 정보"
              onTap: () { Navigator.pop(context); showDialog(context: context, builder: (_) => SongInfoDialog(song: song)); },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistSelector(SongModel song) async {
    final strings = AppStrings.of(context);
    Map<String, List<int>> playlists = await _storageService.getPlaylists();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(strings.selectPlaylist, style: const TextStyle(color: Colors.white)), // "플레이리스트 선택"
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add, color: Colors.greenAccent),
                title: Text(strings.createNewPlaylist, style: const TextStyle(color: Colors.white)), // "새 플레이리스트 생성"
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
                  // "스낵바: ~에 추가되었습니다"
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${strings.addedTo} $name")));
                },
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewPlaylist(SongModel song) {
    final strings = AppStrings.of(context);
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(strings.newPlaylistName, style: const TextStyle(color: Colors.white)), // "새 플레이리스트 이름"
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              hintText: strings.enterName, // "이름을 입력하세요"
              hintStyle: const TextStyle(color: Colors.grey)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.cancel)), // "취소"
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
            child: Text(strings.create, style: const TextStyle(color: Colors.greenAccent)), // "생성"
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(SongModel song) async {
    final strings = AppStrings.of(context);
    TextEditingController renameController = TextEditingController(text: song.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(strings.renameSong, style: const TextStyle(color: Colors.white)), // "곡 이름 변경"
        content: TextField(
          controller: renameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.cancel)),
          TextButton(
            onPressed: () async {
              bool success = await _musicService.renameFile(song.data, renameController.text);
              if (success && mounted) Navigator.pop(context);
            },
            child: Text(strings.change, style: const TextStyle(color: Colors.greenAccent)), // "변경"
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(SongModel song) async {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(strings.deleteSong, style: const TextStyle(color: Colors.white)), // "곡 삭제"
        content: Text(strings.deleteConfirm, style: const TextStyle(color: Colors.grey)), // "정말로 삭제하시겠습니까?"
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.cancel)),
          TextButton(
            onPressed: () async {
              bool success = await _musicService.deleteFile(song.data);
              if (success && mounted) Navigator.pop(context);
            },
            child: Text(strings.delete, style: const TextStyle(color: Colors.redAccent)),
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
          decoration: InputDecoration(
            hintText: AppStrings.of(context).searchHint, // "곡명, 아티스트 검색"
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
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