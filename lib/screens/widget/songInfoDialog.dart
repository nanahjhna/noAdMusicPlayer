import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongInfoDialog extends StatelessWidget {
  final SongModel song;

  const SongInfoDialog({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    double sizeInMB = (song.size / (1024 * 1024));
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      title: const Text("파일 정보", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow("제목", song.title),
            _infoRow("아티스트", song.artist ?? "알 수 없음"),
            _infoRow("앨범", song.album ?? "알 수 없음"),
            _infoRow("파일 형식", song.fileExtension),
            _infoRow("크기", "${sizeInMB.toStringAsFixed(2)} MB"),
            _infoRow("경로", song.data),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("닫기", style: TextStyle(color: Colors.greenAccent)),
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