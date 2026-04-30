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
    final strings = AppStrings.of(context); // 다국어 객체

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(strings.exitApp, style: const TextStyle(color: Colors.white)), // "앱 종료"
        content: Text(strings.exitConfirm, style: const TextStyle(color: Colors.white70)), // "종료하시겠습니까?..."
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.no)), // "아니요"
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.yes, style: const TextStyle(color: Color(0xFF1DB954))), // "예"
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

    final strings = AppStrings.of(context); // 다국어 객체

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
            // 하단 탭 바 다국어 적용
            BottomNavigationBarItem(icon: const Icon(Icons.music_note_rounded), label: strings.tabMusic),
            BottomNavigationBarItem(icon: const Icon(Icons.playlist_play_rounded), label: strings.tabPlaylists),
            BottomNavigationBarItem(icon: const Icon(Icons.settings_rounded), label: strings.tabSettings),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final strings = AppStrings.of(context); // 다국어 객체

    return StreamBuilder<SequenceState?>(
      stream: _audioManager.player.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null || state.currentSource == null) return const SizedBox.shrink();

        final metadata = state.currentSource!.tag as MediaItem;

        return GestureDetector(
          onTap: () => _showPlayerDetail(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ... 진행 바 생략 (기존과 동일)
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
                      metadata.artist ?? strings.unknownArtist, // "알 수 없는 아티스트" 다국어 적용
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ... 재생/닫기 버튼 생략 (기존과 동일)
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // [추가] 상세 화면을 띄우는 함수
  void _showPlayerDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.95,
        // 클래스 이름의 첫 글자는 'P' 대문자입니다.
        child: PlayerDetailScreen(audioManager: _audioManager),
      ),
    );
  }
}