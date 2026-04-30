import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../services/storageService.dart';
import 'widget/SongListView.dart';
import '../app_strings.dart';

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

  Future<void> _loadPlaylists() async {
    final data = await _storageService.getPlaylists();
    if (mounted) {
      setState(() {
        _playlists = data;
      });
    }
  }

  // 2. 플레이리스트 삭제 기능 (다국어 적용)
  Future<void> _deletePlaylist(String name) async {
    final strings = AppStrings.of(context); // [추가]

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(strings.deletePlaylist, style: const TextStyle(color: Colors.white)), // "플레이리스트 삭제"
        content: Text(
          "${strings.deletePlaylistConfirm} '$name'?", // "'이름'을 삭제하시겠습니까?"
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)), // "취소"
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.delete, style: const TextStyle(color: Colors.red)) // "삭제"
          ),
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

  List<SongModel> _getSongsInPlaylist(String name) {
    List<int> ids = _playlists[name] ?? [];
    return widget.allSongs.where((song) => ids.contains(song.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context); // [추가]

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
        // 선택된 폴더명이 없으면 "플레이리스트" 표시
        title: Text(_selectedPlaylistName ?? strings.tabPlaylists,
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
    final strings = AppStrings.of(context); // [추가]

    if (_playlists.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 200),
          Center(child: Text(strings.noPlaylist, style: const TextStyle(color: Colors.grey))), // "생성된 리스트 없음"
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
          // "곡 5개" -> "5 Songs" 등 대응
          subtitle: Text("$count ${strings.songsCount}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () => _deletePlaylist(name),
          ),
          onTap: () => setState(() => _selectedPlaylistName = name),
        );
      },
    );
  }

  // --- 곡 상세 화면 ---
  Widget _buildPlaylistDetail() {
    final strings = AppStrings.of(context); // [추가]
    List<SongModel> songs = _getSongsInPlaylist(_selectedPlaylistName!);

    if (songs.isEmpty) {
      return Center(
        child: Text(strings.emptyPlaylist, style: const TextStyle(color: Colors.grey)), // "곡이 없습니다"
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          // "10곡 재생 가능" -> "10 Songs playable"
          child: Text("${songs.length}${strings.playableSongs}", style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
        ),
        Expanded(
          child: SongListView(
            songs: songs,
            onTap: (index) {
              widget.onPlayPlaylist(songs, index);
            },
            onLongPress: (song) {
              // 필요 시 다국어 적용한 곡 삭제 기능 추가 가능
            },
          ),
        ),
      ],
    );
  }
}