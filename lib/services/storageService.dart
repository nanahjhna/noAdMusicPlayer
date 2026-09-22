import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../utils/logger.dart';

class StorageService {
  // --- 저장 키값 정의 (중앙 관리) ---
  static const String _keyIndex = 'last_index';
  static const String _keyPosition = 'last_position';
  static const String _keySongId = 'last_song_id';
  static const String _keyShuffle = 'isShuffle';
  static const String _keyLoopMode = 'loopMode';
  static const String _keyPlaylists = 'playlists';
  static const String _keyQueue = 'last_queue'; // 이어듣기 복원용 큐

  // 1. 마지막 재생 상태(곡 정보) 저장
  Future<void> saveLastStatus(AudioPlayer player, SongModel song) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIndex, player.currentIndex ?? 0);
    await prefs.setInt(_keyPosition, player.position.inMilliseconds);
    await prefs.setInt(_keySongId, song.id);
  }

  // 1-b. 재생 위치만 저장 (곡 전환 없이 강제 종료되는 케이스 대비, 주기 호출)
  Future<void> saveLastPosition(AudioPlayer player) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPosition, player.position.inMilliseconds);
  }

  // --- 재생 큐 저장/복원 (강제 종료 후 이어듣기) ---
  Future<void> saveQueue(List<int> songIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQueue, jsonEncode(songIds));
  }

  Future<List<int>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyQueue);
    if (data == null || data.isEmpty) return [];
    try {
      return List<int>.from(jsonDecode(data) as List);
    } catch (e) {
      AppLog.e('StorageService', '재생 큐 복원 실패: $e');
      return [];
    }
  }

  // 2. 마지막 재생 상태 복구
  Future<Map<String, dynamic>> restoreLastStatus(List<SongModel> songs) async {
    final prefs = await SharedPreferences.getInstance();

    final int lastIndex = prefs.getInt(_keyIndex) ?? 0;
    final int lastPosition = prefs.getInt(_keyPosition) ?? 0;
    final int? lastSongId = prefs.getInt(_keySongId);

    if (songs.isNotEmpty &&
        lastIndex < songs.length &&
        songs[lastIndex].id == lastSongId) {
      return {
        'index': lastIndex,
        'position': Duration(milliseconds: lastPosition),
      };
    }

    // 저장된 인덱스의 곡이 현재 큐와 불일치하면 0번으로 폴백
    return {
      'index': 0,
      'position': Duration.zero,
    };
  }

  // 3. 재생 모드 저장 (셔플, 반복)
  Future<void> savePlayMode(bool isShuffle, LoopMode loopMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShuffle, isShuffle);
    await prefs.setInt(_keyLoopMode, loopMode.index);
  }

  // 4. 재생 모드 불러오기 (AudioManager에서 호출하는 함수명)
  Future<Map<String, dynamic>> getPlayMode() async {
    final prefs = await SharedPreferences.getInstance();

    // 저장된 값이 없으면 기본값(셔플 꺼짐, 반복 꺼짐) 반환
    final bool isShuffle = prefs.getBool(_keyShuffle) ?? false;
    final int loopModeIndex = prefs.getInt(_keyLoopMode) ?? 0;

    return {
      'shuffle': isShuffle,
      'loopMode': LoopMode.values[loopModeIndex],
    };
  }

  // --- 플레이리스트 관련 로직 ---

  // 모든 플레이리스트 가져오기
  Future<Map<String, List<int>>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyPlaylists);
    if (data == null) return {};

    try {
      Map<String, dynamic> jsonMap = jsonDecode(data);
      return jsonMap.map((key, value) => MapEntry(key, List<int>.from(value)));
    } catch (e) {
      return {};
    }
  }

  // 플레이리스트 저장하기
  Future<void> savePlaylists(Map<String, List<int>> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlaylists, jsonEncode(playlists));
  }

  // 특정 플레이리스트에 곡 추가
  Future<void> addSongToPlaylist(String playlistName, int songId) async {
    final playlists = await getPlaylists();
    if (playlists.containsKey(playlistName)) {
      if (!playlists[playlistName]!.contains(songId)) {
        playlists[playlistName]!.add(songId);
        await savePlaylists(playlists);
      }
    }
  }
}