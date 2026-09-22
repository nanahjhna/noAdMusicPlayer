import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../utils/logger.dart';
import 'storageService.dart';

class AudioManager {
  // 싱글톤 패턴 유지
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer player = AudioPlayer();
  final StorageService _storageService = StorageService();

  StreamSubscription<void>? _noisySub;
  bool _audioSessionReady = false;

  // --- 오디오 세션 (Audio Focus / Ducking / Noisy Intent) ---
  // 앱 시작 시 1회 호출.
  // - 다른 앱이 미디어를 재생하면 Ducking(소리 축소)
  // - 통화/알람 발생 시 자동 일시정지 (포커스 복귀 시 자동 재개)
  // - 이어폰/블루투스 분리 시 즉시 일시정지
  Future<void> initAudioSession() async {
    if (_audioSessionReady) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);

      _noisySub = session.becomingNoisyEventStream.listen((_) {
        AppLog.d('AudioManager', '이어폰/블루투스 분리 감지 → 일시정지');
        pause();
      });
      AppLog.d('AudioManager', '오디오 세션 구성 완료 (포커스/Ducking/Noisy)');
    } catch (e) {
      AppLog.e('AudioManager', '오디오 세션 초기화 실패: $e');
    } finally {
      _audioSessionReady = true;
    }
  }

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

  // --- 재생 큐 상태 저장 (이어듣기 복원용) ---
  Future<void> _saveQueueState(List<SongModel> songs, int index) async {
    await _storageService.saveQueue(songs.map((s) => s.id).toList());
    if (songs.isNotEmpty && index < songs.length) {
      await _storageService.saveLastStatus(player, songs[index]);
    }
  }

  // --- 음악 재생 함수 ---
  Future<void> playMusic(
    List<SongModel> songs, {
    int index = 0,
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty) return;

    try {
      final playlist = createPlaylist(songs);

      await player.setAudioSource(
        playlist,
        initialIndex: index,
        initialPosition: Duration.zero,
      );
      await _saveQueueState(songs, index);

      if (autoPlay) {
        await player.play();
      }
      AppLog.d('AudioManager', '재생 시작: ${songs[index].title}');
    } catch (e) {
      AppLog.e('AudioManager', '음악 재생 중 에러 발생: $e');
    }
  }

  // --- 마지막 재생 상태 복원 (강제 종료 후 이어듣기) ---
  // 저장된 큐의 곡 ID를 현재 라이브러리와 교차 검증해 유효한 곡만 재구성하고,
  // 저장된 인덱스/위치로 seek한다. (자동 재생은 하지 않음 - 사용자 의도 존중)
  Future<bool> restorePlayback(List<SongModel> library) async {
    await initSavedSettings();

    // 1) 저장된 큐 불러오기
    final queueIds = await _storageService.getQueue();
    if (queueIds.isEmpty) {
      AppLog.d('AudioManager', '복원할 재생 큐가 없음 (첫 실행)');
      return false;
    }

    // 2) 라이브러리와 교차 검증 (삭제된 곡 제외)
    final songsById = {for (final s in library) s.id: s};
    final queueSongs = [
      for (final id in queueIds)
        if (songsById.containsKey(id)) songsById[id]!,
    ];
    if (queueSongs.isEmpty) {
      AppLog.d('AudioManager', '큐에 유효한 곡이 없음');
      return false;
    }

    // 3) 저장된 인덱스/위치 로드 (기존 로직 재사용)
    final status = await _storageService.restoreLastStatus(queueSongs);
    final index = status['index'] as int;
    final position = status['position'] as Duration;

    if (index >= queueSongs.length) {
      AppLog.d('AudioManager', '저장된 인덱스 범위 초과 → 복원 중단');
      return false;
    }

    // 4) 큐 로드 후 위치 복원
    await playMusic(queueSongs, index: index, autoPlay: false);
    try {
      await player.seek(position);
      AppLog.d('AudioManager', '복원 완료: index=$index position=${position.inSeconds}s');
      return true;
    } catch (e) {
      AppLog.e('AudioManager', '복원 중 위치 이동 실패: $e');
      return false;
    }
  }

  // --- 기본 제어 로직 ---
  Future<void> play() async => await player.play();
  Future<void> pause() async => await player.pause();

  // [에러 해결용 추가] 정지 메서드
  Future<void> stop() async {
    await player.stop();
    AppLog.d('AudioManager', '음악 재생 정지');
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
      AppLog.e('AudioManager', '설정 로드 실패: $e');
    }
  }

  void dispose() {
    _noisySub?.cancel();
    player.dispose();
  }
}