import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';

class MusicService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // 곡 목록 스캔 (나중에 DB에서 가져오는 로직으로 확장 가능)
  Future<List<SongModel>> fetchSongs() async {
    return await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
  }

  // 파일 이름 변경
  Future<bool> renameFile(String oldPath, String newName) async {
    try {
      final file = File(oldPath);
      final String dir = file.parent.path;
      final String extension = oldPath.split('.').last;
      final String newPath = "$dir/$newName.$extension";

      if (await file.exists()) {
        await file.rename(newPath);
        return true;
      }
    } catch (e) {
      print("Rename Error: $e");
    }
    return false;
  }

  // 파일 삭제
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print("Delete Error: $e");
    }
    return false;
  }
}