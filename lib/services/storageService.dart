import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class StorageService {
  // --- 저장 키값 정의 (오타 방지) ---
  static const String _keyIndex = 'last_index';
  static const String _keyPosition = 'last_position';
  static const String _keySongId = 'last_song_id';

  // 1. 마지막 재생 상태 저장
  Future<void> saveLastStatus(AudioPlayer player, SongModel song) async {
    final prefs = await SharedPreferences.getInstance();

    // 현재 재생 인덱스, 재생 지점(ms), 곡의 고유 ID 저장
    await prefs.setInt(_keyIndex, player.currentIndex ?? 0);
    await prefs.setInt(_keyPosition, player.position.inMilliseconds);
    await prefs.setInt(_keySongId, song.id);
  }

  // 2. 마지막 재생 상태 복구
  // 리턴 타입: Map<String, dynamic>을 통해 인덱스와 위치를 동시에 전달
  Future<Map<String, dynamic>> restoreLastStatus(List<SongModel> songs) async {
    final prefs = await SharedPreferences.getInstance();

    final int lastIndex = prefs.getInt(_keyIndex) ?? 0;
    final int lastPosition = prefs.getInt(_keyPosition) ?? 0;
    final int? lastSongId = prefs.getInt(_keySongId);

    // 데이터 검증: 저장된 인덱스가 현재 곡 목록 범위 내에 있고, ID가 일치하는지 확인
    if (songs.isNotEmpty &&
        lastIndex < songs.length &&
        songs[lastIndex].id == lastSongId) {

      return {
        'index': lastIndex,
        'position': Duration(milliseconds: lastPosition),
      };
    }

    // 일치하지 않으면 처음부터 재생
    return {
      'index': 0,
      'position': Duration.zero,
    };
  }

// (추후 확장) 3. 볼륨 설정이나 테마 설정 등 추가 가능
}