import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioManager {
  // 1. 싱글톤 패턴 적용: 앱 전체에서 단 하나의 AudioManager만 존재하도록 함
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer player = AudioPlayer();

  // 2. 플레이리스트 생성 로직 (예외 처리 및 최적화)
  ConcatenatingAudioSource createPlaylist(List<SongModel> songs) {
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songs.map((s) {
        // 파일 경로가 비어있을 경우를 대비한 처리
        return AudioSource.uri(
          Uri.parse(s.data),
          tag: MediaItem(
            id: '${s.id}',
            title: s.title,
            artist: s.artist ?? "Unknown Artist",
            album: s.album ?? "Unknown Album",
            duration: Duration(milliseconds: s.duration ?? 0),
            artUri: null, // 필요 시 이미지 URI 추가 가능
            extras: {'id': s.id},
          ),
        );
      }).toList(),
    );
  }

  // 3. 통합 제어 로직 (반복 + 셔플 순환)
  // 꺼짐 -> 전체 반복 -> 한 곡 반복 -> 셔플 순으로 모드 변경
  Future<void> nextAllInOneMode() async {
    final bool isShuffle = player.shuffleModeEnabled;
    final LoopMode loopMode = player.loopMode;

    if (!isShuffle && loopMode == LoopMode.off) {
      // 1. 꺼짐 -> 전체 반복
      await player.setShuffleModeEnabled(false);
      await player.setLoopMode(LoopMode.all);
    } else if (!isShuffle && loopMode == LoopMode.all) {
      // 2. 전체 반복 -> 한 곡 반복
      await player.setLoopMode(LoopMode.one);
    } else if (!isShuffle && loopMode == LoopMode.one) {
      // 3. 한 곡 반복 -> 셔플 ON (반복은 전체로 설정)
      await player.setShuffleModeEnabled(true);
      await player.setLoopMode(LoopMode.all);
      await player.shuffle(); // 셔플 켤 때 리스트 섞기
    } else {
      // 4. 셔플 중 -> 모두 꺼짐
      await player.setShuffleModeEnabled(false);
      await player.setLoopMode(LoopMode.off);
    }
  }

  // 4. 개별 셔플 토글 (필요한 경우 유지)
  Future<void> toggleShuffle() async {
    final bool isEnabled = player.shuffleModeEnabled;
    await player.setShuffleModeEnabled(!isEnabled);
    if (!isEnabled) {
      await player.shuffle();
    }
  }

  // 5. 개별 루프 모드 토글 (필요한 경우 유지)
  Future<void> toggleLoopMode() async {
    LoopMode nextMode;
    switch (player.loopMode) {
      case LoopMode.off:
        nextMode = LoopMode.all;
        break;
      case LoopMode.all:
        nextMode = LoopMode.one;
        break;
      case LoopMode.one:
        nextMode = LoopMode.off;
        break;
    }
    await player.setLoopMode(nextMode);
  }

  // 6. 리소스 해제
  void dispose() {
    player.dispose();
  }
}