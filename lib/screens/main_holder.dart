import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/app_strings.dart';
import '../core/design_system.dart';
import '../core/library_service.dart';
import '../core/playback_controller.dart';
import '../utils/logger.dart';
import '../widgets/now_playing_bar.dart';

import 'home.dart';
import 'permission_gate.dart';
import 'play_list.dart';
import 'settings_screen.dart';
import 'widget/player_detail_screen.dart';

/// App shell: owns the library snapshot, the tab state and the lifecycle hooks.
class MainHolder extends StatefulWidget {
  const MainHolder({super.key});

  @override
  State<MainHolder> createState() => _MainHolderState();
}

class _MainHolderState extends State<MainHolder> with WidgetsBindingObserver {
  final LibraryService _libraryService = LibraryService();
  final PlaybackController _controller = PlaybackController.instance;

  int _tab = 0;
  LibrarySnapshot? _library;
  bool _permissionGranted = false;
  bool _checkingPermission = true;
  bool _scanning = false;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A swipe-away or task kill used to lose up to 10s of position, because the
    // only writer was a periodic timer.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _controller.flushResumePoint();
    }
  }

  Future<void> _bootstrap() async {
    _controller.initialize();

    bool granted;
    try {
      granted = await OnAudioQuery().permissionsStatus();
    } catch (e) {
      AppLog.e('MainHolder', 'permission check failed: $e');
      granted = false;
    }
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _checkingPermission = false;
    });

    if (granted) await _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    setState(() {
      _scanning = true;
      _scanError = null;
    });

    try {
      final snapshot = await _libraryService.scan();
      if (!mounted) return;
      setState(() {
        _library = snapshot;
        _scanning = false;
      });
      // Resume the previous queue, cross-checked against the fresh scan.
      await _controller.restoreSession(snapshot.songs);
    } catch (e, stack) {
      AppLog.e('MainHolder', 'library scan failed: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _scanError = e.toString();
      });
    }
  }

  /// Called after a rename/delete so the library and the queue drop the
  /// affected tracks instead of pointing at files that no longer exist.
  Future<void> _refreshAfterMutation(List<SongModel> removed) async {
    await _loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermission) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (!_permissionGranted) {
      return PermissionGate(
        onPermissionChanged: (granted) {
          if (granted && _library == null) _loadLibrary();
        },
        onRetry: _loadLibrary,
      );
    }

    final library = _library;
    if (library == null && _scanning) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (library == null) {
      return _ScanFailed(
        message: _scanError,
        onRetry: _loadLibrary,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  HomeScreen(
                    key: const ValueKey('home'),
                    library: library,
                    controller: _controller,
                    onSongsChanged: _refreshAfterMutation,
                  ),
                  PlaylistScreen(
                    key: const ValueKey('playlists'),
                    library: library.songs,
                    controller: _controller,
                    onLibraryChanged: _loadLibrary,
                  ),
                  SettingsScreen(
                    key: const ValueKey('settings'),
                    onRefreshLibrary: _loadLibrary,
                  ),
                ],
              ),
            ),
            // The mini player is driven by controller state, so it appears on
            // cold start when a session was restored and disappears only when
            // the queue is actually cleared.
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final show = _controller.hasQueue && _controller.currentSong != null;
                return AnimatedSize(
                  duration: AppMotion.normal,
                  curve: AppMotion.enter,
                  alignment: Alignment.bottomCenter,
                  child: show
                      ? NowPlayingBar(
                          controller: _controller,
                          onExpand: _openPlayer,
                        )
                      : const SizedBox(width: double.infinity),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          current: _tab,
          onTap: (index) => setState(() => _tab = index),
        ),
      ),
    );
  }

  void _openPlayer() {
    Navigator.of(context).push(PlayerDetailScreen.route(_controller));
  }

  Future<void> _confirmExit() async {
    final strings = AppStrings.of(context);

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.exitApp),
        content: Text(strings.exitConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              strings.no,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.yes, style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      // Stop playback and persist before the process goes away.
      await _controller.stopAndClear();
      await _controller.flushResumePoint();
      exit(0);
    }
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onTap});

  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          height: AppSizes.navBarHeight,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
        child: NavigationBar(
          selectedIndex: current,
          onDestinationSelected: onTap,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.library_music_outlined),
              selectedIcon: const Icon(Icons.library_music_rounded),
              label: strings.songs,
            ),
            NavigationDestination(
              icon: const Icon(Icons.queue_music_outlined),
              selectedIcon: const Icon(Icons.queue_music_rounded),
              label: strings.playlists,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: strings.settings,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFailed extends StatelessWidget {
  const _ScanFailed({required this.message, required this.onRetry});

  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.scanFailed,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(strings.tryAgain),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
