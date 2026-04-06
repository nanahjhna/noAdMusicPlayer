import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🚀 앱 종료(SystemNavigator)를 위해 추가
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
    const SettingsScreen(), // 설정 화면
  ];

  // 🎵 앱 종료 확인 다이얼로그 함수
  Future<void> _showExitDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("앱 종료", style: TextStyle(color: Colors.white)),
        content: const Text("이 앱을 종료하시겠습니까?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          // '아니요' 누르면 다이얼로그만 닫음
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("아니요", style: TextStyle(color: Colors.grey)),
          ),
          // '예' 누르면 시스템적으로 앱 프로세스 종료
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: const Text("예", style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 기존 Scaffold를 PopScope로 감싸서 뒤로 가기 버튼을 제어합니다.
    return PopScope(
      canPop: false, // 시스템 기본 뒤로 가기 동작을 막음
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 뒤로 가기 버튼이 눌리면 종료 확인 다이얼로그를 띄움
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