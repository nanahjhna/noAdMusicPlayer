import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../app_strings.dart';

class SongInfoDialog extends StatelessWidget {
  final SongModel song;

  const SongInfoDialog({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context); // [추가] 다국어 객체
    double sizeInMB = (song.size / (1024 * 1024));

    return AlertDialog(
      backgroundColor: Colors.grey[850],
      // [변경] "파일 정보" 다국어 적용
      title: Text(strings.fileInfo,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow(strings.infoTitle, song.title), // "제목"
            _infoRow(strings.infoArtist, song.artist ?? strings.unknownArtist), // "아티스트"
            _infoRow(strings.infoAlbum, song.album ?? strings.unknownArtist), // "앨범"
            _infoRow(strings.infoFormat, song.fileExtension), // "파일 형식"
            _infoRow(strings.infoSize, "${sizeInMB.toStringAsFixed(2)} MB"), // "크기"
            _infoRow(strings.infoPath, song.data), // "경로"
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          // [변경] "닫기" 다국어 적용
          child: Text(strings.close, style: const TextStyle(color: Colors.greenAccent)),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}