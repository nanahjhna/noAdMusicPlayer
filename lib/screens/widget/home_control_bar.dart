import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/app_strings.dart';
import '../../core/design_system.dart';
import '../../core/playback_controller.dart';

/// Library summary line plus the two play-mode toggles.
///
/// The previous version crammed shuffle and repeat into a single button cycling
/// through four states (off -> repeat-all -> repeat-one -> shuffle+repeat-all),
/// which is not a pattern any shipping player uses and made the state
/// unreadable. They are separate buttons now, both routed through
/// [PlaybackController] so the choice persists.
class HomeControlBar extends StatelessWidget {
  const HomeControlBar({
    super.key,
    required this.songCount,
    required this.controller,
  });

  final int songCount;
  final PlaybackController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${strings.total} $songCount ${strings.songsCount}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ),
          StreamBuilder<bool>(
            stream: controller.player.shuffleModeEnabledStream,
            builder: (context, snapshot) {
              final active = snapshot.data ?? controller.shuffleEnabled;
              return _Toggle(
                icon: Icons.shuffle_rounded,
                tooltip: strings.shuffle,
                active: active,
                onTap: controller.toggleShuffle,
              );
            },
          ),
          StreamBuilder<LoopMode>(
            stream: controller.player.loopModeStream,
            builder: (context, snapshot) {
              final mode = snapshot.data ?? controller.loopMode;
              return _Toggle(
                icon: mode == LoopMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                tooltip: switch (mode) {
                  LoopMode.one => strings.repeatOne,
                  LoopMode.all => strings.repeatAll,
                  LoopMode.off => strings.repeatOff,
                },
                active: mode != LoopMode.off,
                onTap: controller.cycleLoopMode,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      splashRadius: 20,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Icon(
        icon,
        size: 20,
        color: active ? AppColors.accent : AppColors.textTertiary,
      ),
    );
  }
}
