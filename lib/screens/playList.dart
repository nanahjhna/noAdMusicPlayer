import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../services/storageService.dart';
import 'widget/SongListView.dart';

class PlaylistScreen extends StatefulWidget {
  final List<SongModel> allSongs;
  final Function(List<SongModel>, int) onPlayPlaylist;

  const PlaylistScreen({
    super.key,
    required this.allSongs,
    required this.onPlayPlaylist,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final StorageService _storageService = StorageService();
  Map<String, List<int>> _playlists = {};
  String? _selectedPlaylistName;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  // 1. 데이터 새로고침: 화면이 보일 때나 액션 후 호출
  Future<void> _loadPlaylists() async {
    final data = await _storageService.getPlaylists();
    if (mounted) {
      setState(() {
        _playlists = data;
      });
    }
  }

  // 2. 플레이리스트 삭제 기능 추가
  Future<void> _deletePlaylist(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("플레이리스트 삭제", style: TextStyle(color: Colors.white)),
        content: Text("'$name' 플레이리스트를 삭제하시겠습니까?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final updatedPlaylists = Map<String, List<int>>.from(_playlists);
      updatedPlaylists.remove(name);
      await _storageService.savePlaylists(updatedPlaylists);
      _loadPlaylists();
    }
  }

  // 3. ID를 실제 곡 데이터로 변환
  List<SongModel> _getSongsInPlaylist(String name) {
    List<int> ids = _playlists[name] ?? [];
    // 전체 곡 목록에서 저장된 ID가 포함된 곡만 필터링
    return widget.allSongs.where((song) => ids.contains(song.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 곡 로딩 중 처리
    if (widget.allSongs.isEmpty && _playlists.isNotEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(_selectedPlaylistName ?? "플레이리스트",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: _selectedPlaylistName != null
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => setState(() => _selectedPlaylistName = null),
        )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPlaylists,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlaylists,
        color: Colors.greenAccent,
        backgroundColor: Colors.grey[850],
        child: _selectedPlaylistName == null
            ? _buildPlaylistFolderList()
            : _buildPlaylistDetail(),
      ),
    );
  }

  // --- 폴더(목록) 화면 ---
  Widget _buildPlaylistFolderList() {
    if (_playlists.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: Text("생성된 플레이리스트가 없습니다.", style: TextStyle(color: Colors.grey))),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        String name = _playlists.keys.elementAt(index);
        int count = _playlists[name]?.length ?? 0;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.grey[800]!, Colors.grey[700]!]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.library_music, color: Colors.greenAccent),
          ),
          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text("곡 $count개", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () => _deletePlaylist(name), // 리스트 삭제 메뉴
          ),
          onTap: () => setState(() => _selectedPlaylistName = name),
        );
      },
    );
  }

  // --- 곡 상세 화면 (재생 로직 포함) ---
  Widget _buildPlaylistDetail() {
    List<SongModel> songs = _getSongsInPlaylist(_selectedPlaylistName!);

    if (songs.isEmpty) {
      return const Center(
        child: Text("플레이리스트에 곡이 없습니다.", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        // 상단 플레이리스트 정보 바 (선택 사항)
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: Text("${songs.length}곡 재생 가능", style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
        ),
        Expanded(
          child: SongListView(
            songs: songs,
            onTap: (index) {
              // 🎵 [재생 핵심] 플레이리스트 전체 목록과 클릭한 인덱스를 전달
              widget.onPlayPlaylist(songs, index);
            },
            onLongPress: (song) {
              // 여기서 플레이리스트 내 곡 삭제 기능을 추가할 수 있습니다.
            },
          ),
        ),
      ],
    );
  }
}