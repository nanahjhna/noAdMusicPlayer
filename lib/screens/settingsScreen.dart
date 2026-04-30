import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

import '../app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection(context, "Language", [
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white),
              title: const Text("Change Language"),
              onTap: () => _showLanguageDialog(context),
            ),
          ]),
          _buildSection(context, "About", [
            const ListTile(
              title: Text("App Version"),
              trailing: Text("1.0.0", style: TextStyle(color: Colors.grey)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(title,
              style: const TextStyle(
                  color: Color(0xFF1DB954), fontWeight: FontWeight.bold)),
        ),
        ...children,
      ],
    );
  }

  // 🔥 에러 해결 부분: AlertDialog 구조 수정
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Select Language", style: TextStyle(color: Colors.white)),
        content: Column( // children 대신 content: Column 사용
          mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 차지하도록 설정
          children: [
            _langOption(context, "한국어", 'ko'),
            _langOption(context, "English", 'en'),
            _langOption(context, "日本語", 'ja'),
          ],
        ),
      ),
    );
  }

  Widget _langOption(BuildContext context, String label, String code) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language_code', code);
        if (context.mounted) {
          MyApp.setLocale(context, Locale(code));
          Navigator.pop(context);
        }
      },
    );
  }
}