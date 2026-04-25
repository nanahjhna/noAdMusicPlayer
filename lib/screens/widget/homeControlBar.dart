import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/audioManager.dart';
import '../../services/storageService.dart';

class HomeControlBar extends StatelessWidget {
  final int songCount;
  final AudioManager audioManager;

  // StorageService 인스턴스
  final StorageService _storageService = StorageService();

  HomeControlBar({
    super.key,
    required this.songCount,
    required this.audioManager,
    // 여기서 isShuffle과 loopMode를 받지 않습니다. (내부 StreamBuilder 사용)
  });

  void _handleAllInOneTap() async {
    final player = audioManager.player;
    bool nextShuffle = false;
    LoopMode nextLoop = LoopMode.off;

    // 현재 플레이어 상태 기준 토글 로직
    if (!player.shuffleModeEnabled && player.loopMode == LoopMode.off) {
      nextLoop = LoopMode.all;
    } else if (!player.shuffleModeEnabled && player.loopMode == LoopMode.all) {
      nextLoop = LoopMode.one;
    } else if (!player.shuffleModeEnabled && player.loopMode == LoopMode.one) {
      nextShuffle = true;
      nextLoop = LoopMode.all;
    } else {
      nextShuffle = false;
      nextLoop = LoopMode.off;
    }

    await player.setShuffleModeEnabled(nextShuffle);
    await player.setLoopMode(nextLoop);
    await _storageService.savePlayMode(nextShuffle, nextLoop);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("총 $songCount곡",
              style: const TextStyle(color: Colors.grey, fontSize: 12)),

          // 자체적으로 Stream을 감시하여 UI를 업데이트함
          StreamBuilder<bool>(
            stream: audioManager.player.shuffleModeEnabledStream,
            builder: (context, shuffleSnapshot) {
              return StreamBuilder<LoopMode>(
                stream: audioManager.player.loopModeStream,
                builder: (context, loopSnapshot) {
                  final isShuffle = shuffleSnapshot.data ?? false;
                  final mode = loopSnapshot.data ?? LoopMode.off;

                  IconData iconData = Icons.repeat;
                  Color iconColor = const Color(0xFF1DB954); // Spotify Green

                  if (isShuffle) {
                    iconData = Icons.shuffle;
                  } else if (mode == LoopMode.one) {
                    iconData = Icons.repeat_one;
                  } else if (mode == LoopMode.all) {
                    iconData = Icons.repeat;
                  } else {
                    iconData = Icons.repeat;
                    iconColor = Colors.white;
                  }

                  return IconButton(
                    icon: Icon(iconData, color: iconColor, size: 22),
                    onPressed: _handleAllInOneTap,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}