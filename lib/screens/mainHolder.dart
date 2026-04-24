import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
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

  // 1. 데이터 및 서비스 중앙 관리
  final MusicService _musicService = MusicService();
  final AudioManager _audioManager = AudioManager();
  List<SongModel> _allSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // 2. 앱 실행 시 한 번만 곡 목록을 로드
  Future<void> _loadInitialData() async {
    try {
      final songs = await _musicService.fetchSongs();
      setState(() {
        _allSongs = songs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("곡 로드 중 오류 발생: $e");
      setState(() => _isLoading = false);
    }
  }

  // 3. 페이지 전환 함수 (setState가 호출되어야 화면이 바뀜)
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 4. 앱 종료 확인 다이얼로그
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

    if (result == true) {
      if (Platform.isAndroid) {
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop', true);
        exit(0);
      } else {
        exit(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때는 로딩 화면만 표시
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
      );
    }

    // 5. 각 페이지에 필요한 데이터 전달
    final List<Widget> pages = [
      // HomeScreen에 전체 곡 목록과 오디오 매니저 전달
      HomeScreen(allSongs: _allSongs, audioManager: _audioManager),

      // PlaylistScreen에 전체 곡 목록과 재생 콜백 전달
      PlaylistScreen(
        allSongs: _allSongs,
        onPlayPlaylist: (playlistSongs, index) async {
          final playlist = _audioManager.createPlaylist(playlistSongs);
          await _audioManager.player.setAudioSource(playlist, initialIndex: index);
          _audioManager.player.play();
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
        // 6. IndexedStack을 사용하여 페이지 상태(스크롤 등) 유지
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        // 7. 하단 네비게이션 바
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.black,
          selectedItemColor: const Color(0xFF1DB954),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed, // 아이콘이 3개 이상일 때 밀림 방지
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.music_note_rounded), label: 'Music'),
            BottomNavigationBarItem(icon: Icon(Icons.playlist_play_rounded), label: 'Playlists'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}