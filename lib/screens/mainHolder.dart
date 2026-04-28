import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'home.dart';
import 'playList.dart';
import 'settingsScreen.dart';
import '../services/musicService.dart';
import '../services/audioManager.dart';

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

  // [추가] 미니플레이어 표시 여부를 제어하는 상태 변수
  bool _showMiniPlayer = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadData();

    // [추가] 오디오 상태를 감시하여 곡이 바뀌면 미니플레이어를 다시 노출합니다.
    _audioManager.player.sequenceStateStream.listen((state) {
      if (state?.currentSource != null && !_showMiniPlayer) {
        setState(() => _showMiniPlayer = true);
      }
    });
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
        setState(() => _isLoading = false);
      }
    } catch (e) {
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
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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

    final List<Widget> pages = [
      HomeScreen(allSongs: _allSongs, audioManager: _audioManager),
      PlaylistScreen(
        allSongs: _allSongs,
        onPlayPlaylist: (playlistSongs, index) async {
          await _audioManager.playMusic(playlistSongs, index: index);
          // 곡 재생 시 플레이어 보이게 설정
          setState(() => _showMiniPlayer = true);
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
            // [변경] _showMiniPlayer 상태가 true일 때만 위젯을 띄움
            if (_showMiniPlayer) _buildMiniPlayer(),
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

        final metadata = state.currentSource!.tag as MediaItem;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 진행 바
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
                contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
                leading: QueryArtworkWidget(
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
                    // 재생/일시정지 버튼
                    StreamBuilder<bool>(
                      stream: _audioManager.player.playingStream,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                          onPressed: () => isPlaying ? _audioManager.pause() : _audioManager.play(),
                        );
                      },
                    ),
                    // 다음 곡 버튼
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                      onPressed: () => _audioManager.skipNext(),
                    ),
                    // [추가] 닫기(X) 버튼
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
                      onPressed: () {
                        setState(() {
                          _showMiniPlayer = false; // UI 숨기기
                          _audioManager.stop();     // 음악 정지
                        });
                      },
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