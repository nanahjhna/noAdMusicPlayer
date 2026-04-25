import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'; // 추가됨
import 'package:on_audio_query/on_audio_query.dart';
import 'storageService.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer player = AudioPlayer();
  final StorageService _storageService = StorageService();

  // --- [핵심 수정] SongModel을 MediaItem으로 변환하는 함수 ---
  MediaItem _toMediaItem(SongModel song) {
    return MediaItem(
      id: song.id.toString(),
      album: song.album ?? "Unknown Album",
      title: song.title,
      artist: song.artist ?? "Unknown Artist",
      duration: Duration(milliseconds: song.duration ?? 0),
      // 아트워크(이미지)를 보여주고 싶다면 추가 설정이 필요하지만, 우선 기본값으로 설정
      artUri: null,
      extras: {'url': song.data}, // 실제 경로 저장
    );
  }

  // 대기열 생성 함수
  ConcatenatingAudioSource createPlaylist(List<SongModel> songs) {
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songs.map((song) {
        return AudioSource.uri(
          Uri.parse(Uri.file(song.data).toString()),
          // [수정] tag에 SongModel 대신 MediaItem을 넣어야 합니다.
          tag: _toMediaItem(song),
        );
      }).toList(),
    );
  }

  // 음악 재생 함수
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
  Future<void> skipNext() async => await player.seekToNext();
  Future<void> skipPrev() async => await player.seekToPrevious();

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