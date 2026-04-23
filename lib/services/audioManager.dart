import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioManager {
  // 전역적으로 하나의 플레이어 인스턴스를 유지하기 위해 final 선언
  final AudioPlayer player = AudioPlayer();

  // 1. 플레이리스트 생성 로직
  ConcatenatingAudioSource createPlaylist(List<SongModel> songs) {
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songs.map((s) {
        return AudioSource.uri(
          Uri.parse(s.data),
          tag: MediaItem(
            id: '${s.id}',
            title: s.title,
            artist: s.artist ?? "Unknown",
            album: s.album ?? "Unknown",
            duration: Duration(milliseconds: s.duration ?? 0),
            // artwork를 위해 ID를 넘겨주는 경우도 있음 (추후 확장용)
            extras: {'id': s.id},
          ),
        );
      }).toList(),
    );
  }

  // 2. 셔플 모드 토글
  Future<void> toggleShuffle() async {
    final bool isEnabled = player.shuffleModeEnabled;
    await player.setShuffleModeEnabled(!isEnabled);
    // 셔플을 켤 때 목록을 섞어줌
    if (!isEnabled) {
      await player.shuffle();
    }
  }

  // 3. 루프 모드 토글 (Off -> All -> One 순환)
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

  // 4. 리소스 해제 (앱 종료 시 호출)
  void dispose() {
    player.dispose();
  }
}