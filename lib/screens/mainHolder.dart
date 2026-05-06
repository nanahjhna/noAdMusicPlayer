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
import 'widget/playerDetailScreen.dart';

import '../app_strings.dart';

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

  // 미니플레이어 표시 여부를 제어하는 상태 변수
  bool _showMiniPlayer = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadData();

    // 오디오 상태를 감시하여 곡이 바뀌거나 재생될 때만 미니플레이어를 노출합니다.
    _audioManager.player.sequenceStateStream.listen((state) {
      // [수정] 단순히 소스가 있는 것뿐만 아니라 플레이어가 '유효한(idle이 아닌)' 상태일 때만 켭니다.
      if (state?.currentSource != null &&
          _audioManager.player.processingState != ProcessingState.idle) {
        if (!_showMiniPlayer) {
          setState(() => _showMiniPlayer = true);
        }
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
        // 재생 시간이 30초(30000ms)보다 큰 노래만 필터링 (알람음 제거)
        _allSongs = songs.where((song) => (song.duration ?? 0) > 30000).toList();
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
    final strings = AppStrings.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(strings.exitApp, style: const TextStyle(color: Colors.white)),
        content: Text(strings.exitConfirm, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.no)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.yes, style: const TextStyle(color: Color(0xFF1DB954))),
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

    final strings = AppStrings.of(context);

    final List<Widget> pages = [
      HomeScreen(allSongs: _allSongs, audioManager: _audioManager),
      PlaylistScreen(
        allSongs: _allSongs,
        onPlayPlaylist: (playlistSongs, index) async {
          await _audioManager.playMusic(playlistSongs, index: index);
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
            // 미니플레이어 표시 여부 결정
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
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.music_note_rounded), label: strings.tabMusic),
            BottomNavigationBarItem(icon: const Icon(Icons.playlist_play_rounded), label: strings.tabPlaylists),
            BottomNavigationBarItem(icon: const Icon(Icons.settings_rounded), label: strings.tabSettings),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final strings = AppStrings.of(context);

    return StreamBuilder<SequenceState?>(
      stream: _audioManager.player.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        // 소스가 없으면 아무것도 그리지 않음
        if (state == null || state.currentSource == null) return const SizedBox.shrink();

        final metadata = state.currentSource!.tag as MediaItem;

        return GestureDetector(
          onTap: () => _showPlayerDetail(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                QueryArtworkWidget(
                  id: int.parse(metadata.id),
                  type: ArtworkType.AUDIO,
                  artworkWidth: 50,
                  artworkHeight: 50,
                  nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white, size: 30),
                  artworkBorder: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metadata.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        metadata.artist ?? strings.unknownArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildIconButton(Icons.skip_previous_rounded, 24, () => _audioManager.player.seekToPrevious()),
                          const SizedBox(width: 16),
                          StreamBuilder<bool>(
                            stream: _audioManager.player.playingStream,
                            builder: (context, snapshot) {
                              final isPlaying = snapshot.data ?? false;
                              return _buildIconButton(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                28,
                                    () => isPlaying ? _audioManager.pause() : _audioManager.play(),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildIconButton(Icons.skip_next_rounded, 24, () => _audioManager.player.seekToNext()),
                        ],
                      ),
                    ],
                  ),
                ),
                // [수정된 부분] 닫기 버튼 로직
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () async {
                    // 1. UI 상태를 먼저 false로 변경하여 화면에서 즉시 제거
                    setState(() {
                      _showMiniPlayer = false;
                    });

                    // 2. 음악 정지
                    await _audioManager.player.stop();

                    // [중요] setAudioSource(null)은 에러가 나므로 삭제합니다.
                    // 대신, 재생 목록의 인덱스를 초기화하여 리스너가 다시 반응하지 않게 할 수 있습니다.
                    // (선택 사항) await _audioManager.player.seek(null, index: 0);
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, double size, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  void _showPlayerDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.95,
        child: PlayerDetailScreen(audioManager: _audioManager),
      ),
    );
  }
}