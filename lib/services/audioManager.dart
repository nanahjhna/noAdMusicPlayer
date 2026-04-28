import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'storageService.dart';

class AudioManager {
  // 싱글톤 패턴 유지
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer player = AudioPlayer();
  final StorageService _storageService = StorageService();

  // --- SongModel을 MediaItem으로 변환 (just_audio_background 연동용) ---
  MediaItem _toMediaItem(SongModel song) {
    return MediaItem(
      id: song.id.toString(),
      album: song.album ?? "Unknown Album",
      title: song.title,
      artist: song.artist ?? "Unknown Artist",
      duration: Duration(milliseconds: song.duration ?? 0),
      artUri: null, // 필요 시 URI 추가 가능
      extras: {'url': song.data},
    );
  }

  // --- 대기열 생성 함수 ---
  ConcatenatingAudioSource createPlaylist(List<SongModel> songs) {
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songs.map((song) {
        return AudioSource.uri(
          Uri.parse(Uri.file(song.data).toString()),
          tag: _toMediaItem(song), // 변환된 MediaItem 사용
        );
      }).toList(),
    );
  }

  // --- 음악 재생 함수 ---
  Future<void> playMusic(List<SongModel> songs, {int index = 0}) async {
    if (songs.isEmpty) return;

    try {
      final playlist = createPlaylist(songs);

      await player.setAudioSource(
          playlist,
          initialIndex: index,
          initialPosition: Duration.zero
      );

      await player.play();
      print("음악 재생 시작: ${songs[index].title}");
    } catch (e) {
      print("음악 재생 중 에러 발생: $e");
    }
  }

  // --- 기본 제어 로직 ---
  Future<void> play() async => await player.play();
  Future<void> pause() async => await player.pause();

  // [에러 해결용 추가] 정지 메서드
  Future<void> stop() async {
    await player.stop();
    print("음악 재생 정지");
  }

  Future<void> skipNext() async => await player.seekToNext();
  Future<void> skipPrev() async => await player.seekToPrevious();

  // --- 셔플 및 루프 설정 ---
  Future<void> toggleShuffle() async {
    final bool nextShuffle = !player.shuffleModeEnabled;
    await player.setShuffleModeEnabled(nextShuffle);
    if (nextShuffle) await player.shuffle();
    await _storageService.savePlayMode(nextShuffle, player.loopMode);
  }

  Future<void> toggleLoopMode() async {
    LoopMode nextMode;
    switch (player.loopMode) {
      case LoopMode.off: nextMode = LoopMode.all; break;
      case LoopMode.all: nextMode = LoopMode.one; break;
      case LoopMode.one: nextMode = LoopMode.off; break;
    }
    await player.setLoopMode(nextMode);
    await _storageService.savePlayMode(player.shuffleModeEnabled, nextMode);
  }

  // --- 저장된 설정 로드 ---
  Future<void> initSavedSettings() async {
    try {
      final settings = await _storageService.getPlayMode();
      await player.setShuffleModeEnabled(settings['shuffle'] ?? false);
      await player.setLoopMode(settings['loopMode'] ?? LoopMode.off);
    } catch (e) {
      print("설정 로드 실패: $e");
    }
  }

  void dispose() => player.dispose();
}