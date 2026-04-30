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
    final strings = AppStrings.of(context); // [추가] 다국어 객체

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // [변경] "총 10곡" -> 다국어 대응 (예: Total 10 Songs)
          Text(
            "${strings.total} $songCount${strings.songsCount}",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),

          StreamBuilder<bool>(
            stream: audioManager.player.shuffleModeEnabledStream,
            builder: (context, shuffleSnapshot) {
              return StreamBuilder<LoopMode>(
                stream: audioManager.player.loopModeStream,
                builder: (context, loopSnapshot) {
                  final isShuffle = shuffleSnapshot.data ?? false;
                  final mode = loopSnapshot.data ?? LoopMode.off;

                  IconData iconData = Icons.repeat;
                  Color iconColor = const Color(0xFF1DB954);

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