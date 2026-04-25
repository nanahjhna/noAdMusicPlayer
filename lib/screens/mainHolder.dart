import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'home.dart';
import 'playList.dart';
import 'settingsScreen.dart';
import '../services/musicService.dart';
import '../services/audioManager.dart';
import 'package:just_audio_background/just_audio_background.dart';

class MainHolder extends StatefulWidget {
  const MainHolder({super.key});

  @override
  State<MainHolder> createState() => _MainHolderState();
}

class _MainHolderState extends State<MainHolder> {
  int _selectedIndex = 0;
  final MusicService _musicService = MusicService();
  final AudioManager _audioManager = AudioManager();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _allSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadData();
  }

  Future<void> _checkPermissionsAndLoadData() async {
    try {
      bool permissionStatus = await _audioQuery.permissionsStatus();
      if (!permissionStatus) {
        permissionStatus = await _audioQuery.permissionsRequest();
      }

      if (permissionStatus) {
        await _loadInitialData();
      } else {
        debugPrint("권한이 거부되었습니다.");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("권한 요청 중 에러: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final songs = await _musicService.fetchSongs();
      await _audioManager.initSavedSettings();
      setState(() {
        _allSongs = songs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("데이터 로드 중 오류 발생: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("앱 종료", style: TextStyle(color: Colors.white)),
        content: const Text("앱을 종료하시겠습니까?\n음악 재생이 중단됩니다.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("아니요")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("예", style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
    if (result == true) exit(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
      );
    }

    if (_allSongs.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            // [수정 완료] MainValue.center -> MainAxisAlignment.center
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("노래를 찾을 수 없습니다.", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
                onPressed: _checkPermissionsAndLoadData,
                child: const Text("다시 시도 / 권한 허용", style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
      );
    }

    final List<Widget> pages = [
      HomeScreen(allSongs: _allSongs, audioManager: _audioManager),
      PlaylistScreen(
        allSongs: _allSongs,
        onPlayPlaylist: (playlistSongs, index) async {
          await _audioManager.playMusic(playlistSongs, index: index);
        },
      ),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
            ),
            _buildMiniPlayer(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.black,
          selectedItemColor: const Color(0xFF1DB954),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.music_note_rounded), label: 'Music'),
            BottomNavigationBarItem(icon: Icon(Icons.playlist_play_rounded), label: 'Playlists'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return StreamBuilder<SequenceState?>(
      stream: _audioManager.player.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null || state.currentSource == null) {
          return const SizedBox.shrink();
        }

        // [수정] tag를 MediaItem으로 가져옵니다.
        final metadata = state.currentSource!.tag as MediaItem;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration>(
                stream: _audioManager.player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = _audioManager.player.duration ?? Duration.zero;
                  return LinearProgressIndicator(
                    value: total.inMilliseconds > 0 ? position.inMilliseconds / total.inMilliseconds : 0.0,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                    minHeight: 2,
                  );
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: QueryArtworkWidget(
                  // [수정] MediaItem의 id는 String이므로 int로 파싱해줍니다.
                  id: int.parse(metadata.id),
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
                  artworkBorder: BorderRadius.circular(4),
                ),
                title: Text(
                    metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
                ),
                subtitle: Text(
                    metadata.artist ?? "Unknown",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<bool>(
                      stream: _audioManager.player.playingStream,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 35),
                          onPressed: () => isPlaying ? _audioManager.pause() : _audioManager.play(),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 30),
                      onPressed: () => _audioManager.skipNext(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}