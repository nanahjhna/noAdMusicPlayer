import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/app_strings.dart';
import '../../core/design_system.dart';

Future<void> showSongInfoDialog(BuildContext context, SongModel song) {
  return showDialog<void>(
    context: context,
    builder: (_) => SongInfoDialog(song: song),
  );
}

class SongInfoDialog extends StatelessWidget {
  const SongInfoDialog({super.key, required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final sizeInMb = song.size / (1024 * 1024);
    final duration = Duration(milliseconds: song.duration ?? 0);

    return AlertDialog(
      title: Text(strings.fileInfo),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(strings.infoTitle, song.title),
            _row(strings.infoArtist, _orUnknown(song.artist, strings.unknownArtist)),
            _row(strings.infoAlbum, _orUnknown(song.album, strings.unknownAlbum)),
            _row(strings.infoFormat, song.fileExtension.toUpperCase()),
            _row(strings.infoDuration, _formatDuration(duration)),
            _row(strings.infoSize, '${sizeInMb.toStringAsFixed(2)} MB'),
            _row(strings.infoPath, song.data),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            strings.close,
            style: const TextStyle(color: AppColors.accent),
          ),
        ),
      ],
    );
  }

  String _orUnknown(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
