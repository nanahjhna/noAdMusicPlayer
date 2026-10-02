import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/app_strings.dart';
import '../core/design_system.dart';
import '../core/library_service.dart';
import '../core/song_keys.dart';
import '../services/storage_service.dart';
import '../screens/widget/song_info_dialog.dart';
import 'artwork.dart';

/// Shared bottom sheet for per-track actions (rename / playlist / delete /
/// file info).
///
/// [onChanged] receives the tracks whose files were mutated so the caller can
/// trigger a rescan and drop them from the live queue.
Future<void> showSongActions(
  BuildContext context, {
  required SongModel song,
  required void Function(List<SongModel> songs) onChanged,
  String? removeFromPlaylist,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _SongActionsSheet(
      song: song,
      onChanged: onChanged,
      removeFromPlaylist: removeFromPlaylist,
    ),
  );
}

class _SongActionsSheet extends StatefulWidget {
  const _SongActionsSheet({
    required this.song,
    required this.onChanged,
    this.removeFromPlaylist,
  });

  final SongModel song;
  final void Function(List<SongModel> songs) onChanged;
  final String? removeFromPlaylist;

  @override
  State<_SongActionsSheet> createState() => _SongActionsSheetState();
}

class _SongActionsSheetState extends State<_SongActionsSheet> {
  final LibraryService _service = LibraryService();
  final StorageService _storage = StorageService();
  bool _busy = false;

  SongModel get _song => widget.song;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighest,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                SongArtwork(songId: _song.id, size: AppSizes.artworkList),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _song.artist?.trim().isNotEmpty == true
                            ? _song.artist!.trim()
                            : strings.unknownArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          _action(
            icon: Icons.drive_file_rename_outline_rounded,
            label: strings.rename,
            onTap: _rename,
          ),
          _action(
            icon: Icons.playlist_add_rounded,
            label: strings.addToPlaylist,
            color: AppColors.accent,
            onTap: _addToPlaylist,
          ),
          if (widget.removeFromPlaylist != null)
            _action(
              icon: Icons.playlist_remove_rounded,
              label: strings.removeFromPlaylist,
              color: AppColors.danger,
              onTap: _removeFromPlaylist,
            ),
          _action(
            icon: Icons.info_outline_rounded,
            label: strings.fileInfo,
            color: AppColors.textSecondary,
            onTap: () {
              Navigator.pop(context);
              showSongInfoDialog(context, _song);
            },
          ),
          _action(
            icon: Icons.delete_outline_rounded,
            label: strings.delete,
            color: AppColors.danger,
            onTap: _delete,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 14)),
      onTap: _busy ? null : onTap,
    );
  }

  Future<void> _rename() async {
    final strings = AppStrings.of(context);
    final nameController = TextEditingController(text: _song.title);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.renameSong),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: strings.enterName,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              strings.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, nameController.text),
            child: Text(strings.done, style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (newName == null || !mounted) return;

    setState(() => _busy = true);
    final error = await _service.renameSong(_song, newName);
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      _toast(switch (error) {
        'invalid' => strings.invalidName,
        'exists' => strings.playlistExists,
        _ => strings.renameFailed,
      });
      return;
    }
    if (mounted) Navigator.pop(context);
    // A rename changes the stable key, so the whole library has to be rescanned.
    widget.onChanged(const []);
  }

  Future<void> _addToPlaylist() async {
    final strings = AppStrings.of(context);
    final playlists = await _storage.getPlaylists();
    if (!mounted) return;

    final selection = await showDialog<Object>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.selectPlaylist),
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_rounded, color: AppColors.accent),
                  title: Text(
                    strings.createNewPlaylist,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () => Navigator.pop(dialogContext, _CreatePlaylistSignal()),
                ),
                if (playlists.isNotEmpty)
                  const Divider(height: 1, color: AppColors.divider),
                for (final name in playlists.keys)
                  ListTile(
                    leading: const Icon(
                      Icons.queue_music_rounded,
                      color: AppColors.textSecondary,
                    ),
                    title: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      '${playlists[name]!.length} ${strings.songsCount}',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => Navigator.pop(dialogContext, name),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;

    String target;
    if (selection is _CreatePlaylistSignal) {
      target = await _promptNewPlaylist();
    } else if (selection is String) {
      target = selection;
    } else {
      return;
    }

    if (target.isEmpty) return;
    await _storage.addSongsToPlaylist(target, [stableSongKey(_song)]);
    if (!mounted) return;
    Navigator.pop(context);
    _toast('${_song.title} ${strings.songAdded} $target');
    widget.onChanged(const []);
  }

  Future<String> _promptNewPlaylist() async {
    final strings = AppStrings.of(context);
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.newPlaylistName),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: strings.enterName,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              strings.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, nameController.text.trim()),
            child: Text(strings.create, style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    return name ?? '';
  }

  Future<void> _removeFromPlaylist() async {
    final name = widget.removeFromPlaylist!;
    await _storage.removeSongFromPlaylist(name, stableSongKey(_song));
    if (!mounted) return;
    Navigator.pop(context);
    _toast(
      '${_song.title} ${AppStrings.of(context).removedFromPlaylist} $name',
    );
    widget.onChanged(const []);
  }

  Future<void> _delete() async {
    final strings = AppStrings.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteSong),
        content: Text(strings.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              strings.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.delete, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final ok = await _service.deleteSong(_song);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      _toast(strings.deleteFailed);
      return;
    }
    if (mounted) Navigator.pop(context);
    widget.onChanged([_song]);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Sentinel so the playlist picker can distinguish "create new" from a
/// playlist name that happens to be a [String].
class _CreatePlaylistSignal {
  const _CreatePlaylistSignal();
}
