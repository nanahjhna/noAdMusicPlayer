import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home.dart';
import 'settingsScreen.dart';

class MainHolder extends StatefulWidget {
  const MainHolder({super.key});

  @override
  State<MainHolder> createState() => _MainHolderState();
}

class _MainHolderState extends State<MainHolder> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const Center(child: Text("Playlists (Coming Soon)")),
    const SettingsScreen(),
  ];

  // 🎵 앱과 오디오 서비스를 완전히 종료하고 태스크까지 삭제하는 함수
  Future<void> _showExitDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("앱 종료", style: TextStyle(color: Colors.white)),
        content: const Text(
          "이 앱을 종료하시겠습니까?\n종료 시 재생 중인 음악도 즉시 정지됩니다.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("아니요", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              // 🚀 1. 다이얼로그 먼저 닫기
              Navigator.of(context).pop();

              if (Platform.isAndroid) {
                // 🚀 2. 안드로이드 전용: 태스크 목록에서 완전히 제거하고 종료
                // 이 명령은 최근 앱 목록(Task)에서 카드를 삭제하고 프로세스를 종료합니다.
                await SystemChannels.platform.invokeMethod('SystemNavigator.pop', true);

                // 위 명령이 비동기라 바로 종료되지 않을 수 있으므로 0.2초 뒤 강제 종료
                await Future.delayed(const Duration(milliseconds: 200));
                exit(0);
              } else {
                exit(0);
              }
            },
            child: const Text("예", style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _showExitDialog(context);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.black,
          selectedItemColor: const Color(0xFF1DB954),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Music'),
            BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'Playlists'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}