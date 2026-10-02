import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/app_scope.dart';
import 'core/app_strings.dart';
import 'core/design_system.dart';
import 'screens/main_holder.dart';
import 'services/app_update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Anything thrown here used to abort main() *before* runApp(), so the app
  // came up as an empty black window with no visible error. Catching it and
  // rendering it is the difference between "the app is broken" and "the app
  // tells me what is broken".
  Object? initError;
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.han.noadmusic.player.audio',
      androidNotificationChannelName: 'Music Playback',
      // A white silhouette, not the launcher icon. Using mipmap/ic_launcher makes
      // the status bar entry look tinted and low-resolution.
      androidNotificationIcon: 'drawable/ic_stat_music',
      // Keep the notification while paused so playback can be resumed from the
      // lock screen without reopening the app.
      //
      // `androidNotificationOngoing` must stay off: audio_service asserts that
      // it is not combined with `androidStopForegroundOnPause: false`, and
      // documents it as a no-op in that case — the platform already forces an
      // ongoing notification while the foreground service is running, which is
      // exactly the behaviour wanted here.
      androidStopForegroundOnPause: false,
    );
  } catch (e) {
    initError = e;
    debugPrint('[main] JustAudioBackground.init failed: $e');
  }

  runApp(NoAdMusicApp(initError: initError));
}

class NoAdMusicApp extends StatefulWidget {
  const NoAdMusicApp({super.key, this.initError});

  /// Set when background audio setup failed before the first frame. The app
  /// still builds so the failure is on screen rather than a blank window.
  final Object? initError;

  @override
  State<NoAdMusicApp> createState() => _NoAdMusicAppState();
}

class _NoAdMusicAppState extends State<NoAdMusicApp> {
  late final AppScopeState _scope = AppScopeState(const Locale('ko'));

  @override
  void initState() {
    super.initState();
    _applyPersistedLocale();
  }

  Future<void> _applyPersistedLocale() async {
    final code = await AppScope.loadPersistedLocale();
    if (!mounted) return;
    await _scope.setLanguage(code);
  }

  @override
  Widget build(BuildContext context) {
    final initError = widget.initError;
    if (initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                '재생 초기화에 실패했습니다.\n\n$initError',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AppScope(
      state: _scope,
      child: AnimatedBuilder(
        animation: _scope,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // Title is resolved per-locale instead of the hard-coded
            // 'No Ad Music' that ignored the language setting.
            onGenerateTitle: (context) => AppStrings.of(context).appName,
            locale: _scope.locale,
            supportedLocales: const [
              Locale('ko'),
              Locale('en'),
              Locale('ja'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildAppTheme(),
            home: const _Bootstrap(),
          );
        },
      ),
    );
  }
}

/// Waits for the stored locale before the first frame that uses it.
///
/// The previous splash slept for a hard-coded 2 seconds unconditionally, which
/// delayed every cold start and hid a fast library scan behind a spinner.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late final Future<void> _ready = _waitForLocale();
  bool _updateCheckStarted = false;

  Future<void> _waitForLocale() async {
    final code = await AppScope.loadPersistedLocale();
    if (!mounted) return;
    final scope = AppScope.read(context);
    if (scope.locale.languageCode != code) {
      await scope.setLanguage(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.accent,
                    size: 72,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    strings.appName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!_updateCheckStarted) {
          _updateCheckStarted = true;
          // Fire-and-forget: the UI must not wait on a network round trip.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkUpdatesOnStartup();
          });
        }
        return const MainHolder();
      },
    );
  }

  /// Asks Play once per cold start whether a newer release exists.
  ///
  /// Runs after the first frame so the dialog has a Material ancestor and does
  /// not delay the library scan. Failures are silent by design: a user who
  /// cannot reach Play should still get a working player.
  Future<void> _checkUpdatesOnStartup() async {
    const service = AppUpdateService();
    final status = await service.check();
    if (!mounted || status != UpdateStatus.available) return;
    await promptUpdateIfAvailable(context, service, status: status);
  }
}
