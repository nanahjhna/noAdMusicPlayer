import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/app_strings.dart';
import '../core/design_system.dart';
import '../core/playback_controller.dart';
import '../core/song_keys.dart';
import '../services/storage_service.dart';
import '../widgets/song_actions.dart';
import 'widget/song_item.dart';

/// Playlist browser.
///
/// Two behavioural bugs are fixed here:
///  * songs were resolved by filtering the title-sorted library, so a playlist
///    played alphabetically instead of in the order the user added them;
///  * entries were stored as MediaStore row ids, which change on rescan and
///    silently emptied playlists. Keys are now resolved through
///    [reconcileKeys] and rendered in stored order.
class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({
    super.key,
    required this.library,
    required this.controller,
    required this.onLibraryChanged,
  });

  final List<SongModel> library;
  final PlaybackController controller;
  final VoidCallback onLibraryChanged;

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final StorageService _storage = StorageService();

  Map<String, List<String>> _playlists = {};
  String? _openName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PlaylistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The IndexedStack keeps this alive, so a library rescan (after a delete or
    // rename) has to be reflected explicitly.
    if (!identical(oldWidget.library, widget.library) && _openName != null) {
      _load();
    }
  }

  Future<void> _load() async {
    final data = await _storage.getPlaylists();
    if (!mounted) return;
    setState(() {
      _playlists = data;
      _loading = false;
    });
  }

  /// Resolves a playlist's stored keys to live tracks, in stored order.
  List<SongModel> _songsOf(String name) {
    final keys = _playlists[name] ?? const <String>[];
    final reconciled = reconcileKeys(keys, widget.library);
    final byKey = {for (final song in widget.library) stableSongKey(song): song};
    return [
      for (final key in reconciled)
        if (byKey[key] != null) byKey[key]!,
    ];
  }

  /// Stored entries whose file no longer exists on the device.
  int _missingCount(String name) {
    final stored = _playlists[name] ?? const <String>[];
    return stored.length - _songsOf(name).length;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      children: [
        _Header(
          title: _openName ?? strings.playlists,
          onBack: _openName == null ? null : () => setState(() => _openName = null),
          onRefresh: _load,
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  backgroundColor: AppColors.surfaceHigh,
                  child: _openName == null
                      ? _buildFolderList(strings)
                      : _buildDetail(strings, _openName!),
                ),
        ),
      ],
    );
  }

  Widget _buildFolderList(AppStrings strings) {
    if (_playlists.isEmpty) {
      return _ScrollableEmpty(
        icon: Icons.queue_music_rounded,
        title: strings.noPlaylist,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final name = _playlists.keys.elementAt(index);
        final count = _playlists[name]?.length ?? 0;
        final missing = _missingCount(name);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.library_music_rounded, color: AppColors.accent),
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            missing > 0
                ? '$count ${strings.songsCount} · $missing ${strings.missing}'
                : '$count ${strings.songsCount}',
            style: TextStyle(
              color: missing > 0 ? AppColors.danger : AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
          trailing: IconButton(
            onPressed: () => _showPlaylistMenu(name),
            splashRadius: 20,
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textTertiary),
          ),
          onTap: () => setState(() => _openName = name),
        );
      },
    );
  }

  Widget _buildDetail(AppStrings strings, String name) {
    final songs = _songsOf(name);

    if (songs.isEmpty) {
      return _ScrollableEmpty(
        icon: Icons.music_off_outlined,
        title: strings.emptyPlaylist,
      );
    }

    return Column(
      children: [
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${songs.length} ${strings.songsCount}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  widget.controller.playFromList(
                    contextSongs: songs,
                    index: 0,
                    source: 'playlist:$name',
                    label: name,
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(strings.play),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) => ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              itemCount: songs.length,
              onReorder: (oldIndex, newIndex) {
                // ReorderableListView reports the insertion slot, which is one
                // past the target when moving down the list.
                final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
                _storage.movePlaylistItem(name, oldIndex, target);
                _load();
              },
              proxyDecorator: (child, index, animation) => Material(
                color: AppColors.surfaceHigh,
                elevation: 6,
                child: child,
              ),
              itemBuilder: (context, index) {
                final song = songs[index];
                final isCurrent =
                    widget.controller.currentKey == stableSongKey(song);
                return SongListRow(
                  key: ValueKey('pl_${stableSongKey(song)}'),
                  index: index,
                  song: song,
                  isCurrent: isCurrent,
                  isPlaying: widget.controller.player.playing,
                  onTap: () => widget.controller.playFromList(
                    contextSongs: songs,
                    index: index,
                    source: 'playlist:$name',
                    label: name,
                  ),
                  onLongPress: () => showSongActions(
                    context,
                    song: song,
                    removeFromPlaylist: name,
                    onChanged: (_) {
                      _load();
                      widget.onLibraryChanged();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPlaylistMenu(String name) async {
    final strings = AppStrings.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
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
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded, color: AppColors.accent),
              title: Text(
                strings.play,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                final songs = _songsOf(name);
                if (songs.isEmpty) return;
                widget.controller.playFromList(
                  contextSongs: songs,
                  index: 0,
                  source: 'playlist:$name',
                  label: name,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded,
                  color: AppColors.textPrimary),
              title: Text(
                strings.renamePlaylist,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _renamePlaylist(name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: Text(
                strings.deletePlaylist,
                style: const TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _deletePlaylist(name);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _renamePlaylist(String name) async {
    final strings = AppStrings.of(context);
    final nameController = TextEditingController(text: name);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.renamePlaylist),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          cursorColor: AppColors.accent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, nameController.text.trim()),
            child: Text(strings.done, style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || result == name) return;
    await _storage.renamePlaylist(name, result);
    if (!mounted) return;
    if (_openName == name) {
      setState(() => _openName = result);
    } else {
      await _load();
    }
  }

  Future<void> _deletePlaylist(String name) async {
    final strings = AppStrings.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deletePlaylist),
        content: Text('${strings.deletePlaylistConfirm}\n\n$name'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.delete, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _storage.deletePlaylist(name);
    if (!mounted) return;
    setState(() => _openName = null);
    await _load();
  }
}

// ======================================================================
// Local widgets
// ======================================================================

class _Header extends StatelessWidget {
  const _Header({required this.title, this.onBack, this.onRefresh});

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        MediaQuery.paddingOf(context).top + AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            )
          else
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _ScrollableEmpty extends StatelessWidget {
  const _ScrollableEmpty({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
        Icon(icon, size: 44, color: AppColors.disabled),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
