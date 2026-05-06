import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/audioManager.dart';
import '../../services/storageService.dart';
import '../../app_strings.dart';

class HomeControlBar extends StatelessWidget {
  final int songCount;
  final AudioManager audioManager;

  final StorageService _storageService = StorageService();

  HomeControlBar({
    super.key,
    required this.songCount,
    required this.audioManager,
  });

  void _handleAllInOneTap() async {
    final player = audioManager.player;
    bool nextShuffle = false;
    LoopMode nextLoop = LoopMode.off;

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
    final strings = AppStrings.of(context); // 다국어 객체

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 총 곡 수 표시 (다국어 대응)
          Text(
            "${strings.total} $songCount${strings.songsCount}",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),

          // 셔플 및 반복 모드 상태에 따른 아이콘 표시
          StreamBuilder<bool>(
            stream: audioManager.player.shuffleModeEnabledStream,
            builder: (context, shuffleSnapshot) {
              return StreamBuilder<LoopMode>(
                stream: audioManager.player.loopModeStream,
                builder: (context, loopSnapshot) {
                  final isShuffle = shuffleSnapshot.data ?? false;
                  final mode = loopSnapshot.data ?? LoopMode.off;

                  // 기본 설정: 흰색 / 반복 아이콘
                  IconData iconData = Icons.repeat;
                  Color iconColor = Colors.white;

                  if (isShuffle) {
                    // 셔플 모드: 아이콘은 셔플이지만 색상은 흰색
                    iconData = Icons.shuffle;
                    iconColor = Colors.white;
                  } else if (mode == LoopMode.one) {
                    // 한 곡 반복 모드: 아이콘은 1이지만 색상은 흰색
                    iconData = Icons.repeat_one;
                    iconColor = Colors.white;
                  } else {
                    // 그 외 (반복 꺼짐 등): 흰색
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