import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../services/storage_service.dart';
import '../utils/logger.dart';
import 'song_keys.dart';

/// Identity of the loaded queue.
///
/// The previous implementation called `setAudioSource` with a brand new
/// `ConcatenatingAudioSource` on *every* song tap. On a 5,000 track library that
/// meant 5,000 URI parses plus a platform round trip per tap, which is where the
/// freeze-on-tap came from — and it also threw away just_audio's
/// `shuffleOrder`, so shuffle silently reverted to sequential order on the very
/// next tap.
///
/// Comparing the queue by identity lets the common case (`tap another song in
/// the same list`) collapse to a single `seek`.
@immutable
class QueueIdentity {
  const QueueIdentity({required this.source, required this.keys});

  /// Human-readable origin, e.g. `library` or `playlist:Focus`.
  final String source;

  /// Stable song keys in playback order.
  final List<String> keys;

  bool matches(QueueIdentity other) {
    if (other.source != source) return false;
    if (other.keys.length != keys.length) return false;
    for (var i = 0; i < keys.length; i++) {
      if (other.keys[i] != keys[i]) return false;
    }
    return true;
  }
}

/// Single owner of the playback queue, the player and the play-mode state.
///
/// Every screen goes through this object, so there is exactly one place where
/// shuffle/loop get toggled (previously three entry points disagreed, and the
/// one in the full-screen player skipped persistence entirely — hence "shuffle
/// resets on every launch").
class PlaybackController extends ChangeNotifier {
  PlaybackController._();

  static final PlaybackController instance = PlaybackController._();

  final AudioPlayer player = AudioPlayer();
  final StorageService _storage = StorageService();

  QueueIdentity? _queue;
  List<String> _queueKeys = const <String>[];
  List<SongModel> _queueSongs = const <SongModel>[];

  bool _shuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  bool _sessionReady = false;
  bool _initialized = false;
  String _queueSourceLabel = '';

  StreamSubscription<void>? _noisySubscription;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<int?>? _indexSubscription;
  StreamSubscription<ProcessingState>? _stateSubscription;
  Timer? _positionSaveTimer;
  Duration _lastSavedPosition = Duration.zero;
  int? _lastSavedIndex;
  bool _wasPlayingBeforeInterruption = false;

  // ------------------------------------------------------------------
  // Read-only state for the UI
  // ------------------------------------------------------------------

  AudioPlayer get audio => player;
  List<SongModel> get queue => _queueSongs;

  /// Where the current queue came from, e.g. `playlist:Focus`.
  String get queueSourceLabel => _queueSourceLabel;

  bool get shuffleEnabled => _shuffleEnabled || player.shuffleModeEnabled;
  LoopMode get loopMode => _loopMode;

  /// True once a queue is loaded and the player still holds it — i.e. the mini
  /// player has something meaningful to show.
  bool get hasQueue => _queue != null && player.audioSource != null;

  /// True when the player finished or was explicitly stopped.
  bool get isStopped => !hasQueue || player.processingState == ProcessingState.idle;

  int? get currentIndex => player.currentIndex;

  /// Index within the queue for [song], or null when it is not queued.
  int? indexOfSong(SongModel song) {
    final key = stableSongKey(song);
    for (var i = 0; i < _queueSongs.length; i++) {
      if (stableSongKey(_queueSongs[i]) == key) return i;
    }
    return null;
  }

  SongModel? get currentSong {
    final index = player.currentIndex;
    if (index == null || index < 0 || index >= _queueSongs.length) return null;
    return _queueSongs[index];
  }

  /// Stable key of the playing track — used for the resume-point guard.
  String? get currentKey {
    final index = player.currentIndex;
    if (index == null || index < 0 || index >= _queueKeys.length) return null;
    return _queueKeys[index];
  }

  /// The queue in the order it will actually play.
  ///
  /// With shuffle on, just_audio keeps the original children order and applies
  /// a separate `shuffleIndices` permutation, so the visible queue has to be
  /// permuted to match what the listener will hear.
  List<int> get playbackOrder {
    final count = _queueSongs.length;
    final indices = player.shuffleIndices;
    if (shuffleEnabled && indices != null && indices.length == count) {
      return indices;
    }
    return List<int>.generate(count, (i) => i);
  }

  // ------------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _configureAudioSession();

    final playMode = await _storage.getPlayMode();
    _shuffleEnabled = playMode.shuffle;
    _loopMode = playMode.loop;

    // Throttled resume-point writer. A timer rather than `positionStream`, so a
    // seek-heavy UI cannot spam SharedPreferences.
    _positionSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _persistResumePoint(player.position);
    });

    // A track change is the one moment the resume point must be exact, so it is
    // written immediately instead of waiting for the next tick.
    _indexSubscription = player.currentIndexStream.listen((index) {
      if (index != _lastSavedIndex) {
        _lastSavedPosition = Duration.zero;
        _persistResumePoint(Duration.zero, force: true);
      }
      notifyListeners();
    });

    _stateSubscription = player.processingStateStream.listen((_) {
      notifyListeners();
    });
  }

  Future<void> _configureAudioSession() async {
    if (_sessionReady) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Pause on headphone/Bluetooth disconnect so audio does not leak out of
      // the speaker, matching every commercial player.
      _noisySubscription = session.becomingNoisyEventStream.listen((_) {
        AppLog.d('Playback', 'noisy event -> pause');
        unawaited(player.pause());
      });

      // Keep the play button in sync after a phone call / alarm steals focus.
      _interruptionSubscription = session.interruptionEventStream.listen((event) {
        if (event.begin) {
          _wasPlayingBeforeInterruption = player.playing;
        } else if (_wasPlayingBeforeInterruption) {
          _wasPlayingBeforeInterruption = false;
          unawaited(player.play());
        }
        notifyListeners();
      });

      _sessionReady = true;
      AppLog.d('Playback', 'audio session configured');
    } catch (e) {
      AppLog.e('Playback', 'audio session init failed: $e');
    }
  }

  // ------------------------------------------------------------------
  // Queue control
  // ------------------------------------------------------------------

  /// Plays [songs] starting at [index].
  ///
  /// Reuses the loaded playlist when [source] + key order match, which makes
  /// repeated taps O(1) instead of rebuilding the whole source.
  Future<void> playQueue({
    required List<SongModel> songs,
    required int index,
    required String source,
    String? label,
    bool autoPlay = true,
    Duration initialPosition = Duration.zero,
  }) async {
    if (songs.isEmpty) return;
    if (index < 0 || index >= songs.length) index = 0;

    final keys = stableSongKeys(songs);
    final identity = QueueIdentity(source: source, keys: keys);
    final isSameQueue = _queue?.matches(identity) ?? false;

    if (isSameQueue) {
      await player.seek(initialPosition, index: index);
      if (autoPlay) await player.play();
      _persistResumePoint(initialPosition, force: true);
      notifyListeners();
      return;
    }

    try {
      await player.setAudioSource(
        _buildSource(songs),
        initialIndex: index,
        initialPosition: initialPosition,
      );

      _queue = identity;
      _queueKeys = keys;
      _queueSongs = songs;
      _queueSourceLabel = label ?? source;

      // A fresh ConcatenatingAudioSource starts with an identity
      // `shuffleOrder`, so re-apply the modes or shuffle would be a no-op
      // flag that plays sequentially.
      await _applyPlayMode();

      await _storage.saveQueue(keys, _queueSourceLabel);

      if (autoPlay) await player.play();
      _persistResumePoint(initialPosition, force: true);
      notifyListeners();
      AppLog.d('Playback', 'queue loaded: $source (${songs.length} tracks)');
    } catch (e) {
      AppLog.e('Playback', 'playQueue failed: $e');
    }
  }

  /// Plays a single song but keeps the surrounding context of [contextSongs].
  Future<void> playFromList({
    required List<SongModel> contextSongs,
    required int index,
    required String source,
    String? label,
    bool autoPlay = true,
  }) {
    return playQueue(
      songs: contextSongs,
      index: index,
      source: source,
      label: label,
      autoPlay: autoPlay,
    );
  }

  /// Jumps to an absolute position inside the currently loaded queue.
  Future<void> jumpTo(int queueIndex) async {
    if (queueIndex < 0 || queueIndex >= _queueSongs.length) return;
    await player.seek(Duration.zero, index: queueIndex);
    if (!player.playing) await player.play();
    _persistResumePoint(Duration.zero, force: true);
    notifyListeners();
  }

  ConcatenatingAudioSource _buildSource(List<SongModel> songs) {
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: [
        for (final song in songs)
          AudioSource.uri(Uri.file(song.data), tag: _toMediaItem(song)),
      ],
    );
  }

  MediaItem _toMediaItem(SongModel song) {
    final artist = (song.artist ?? '').trim();
    final album = (song.album ?? '').trim();
    return MediaItem(
      // Stable key as the id: MediaStore ids are not unique across rescans and
      // are used to look up artwork in several widgets.
      id: stableSongKey(song),
      album: album.isEmpty ? null : album,
      title: song.title,
      artist: artist.isEmpty ? null : artist,
      duration: Duration(milliseconds: song.duration ?? 0),
      extras: {'url': song.data, 'songId': song.id},
    );
  }

  // ------------------------------------------------------------------
  // Transport
  // ------------------------------------------------------------------

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> togglePlayPause() =>
      player.playing ? pause() : play();
  Future<void> skipNext() => player.seekToNext();
  Future<void> skipPrevious() => player.seekToPrevious();

  /// Commercial-player behaviour: tapping "previous" within the first few
  /// seconds restarts the track, otherwise it jumps back a track.
  Future<void> skipPreviousOrRestart() async {
    if (player.position > const Duration(seconds: 4)) {
      await player.seek(Duration.zero);
      return;
    }
    if ((player.currentIndex ?? 0) > 0) {
      await player.seekToPrevious();
      return;
    }
    await player.seek(Duration.zero);
  }

  Future<void> seek(Duration position) => player.seek(position);

  /// Stops playback and drops the queue. Backs the "stop" action in the queue
  /// sheet — there is deliberately no X button on the mini player (closing the
  /// bar used to kill playback with no way to get it back).
  Future<void> stopAndClear() async {
    await player.stop();
    // just_audio 0.9.x has no `setAudioSource(null)`; an empty playlist is the
    // supported way to unload. `preload: false` keeps the platform from being
    // asked to load a zero-item playlist, so this can never throw.
    await player.setAudioSource(
      ConcatenatingAudioSource(children: const <AudioSource>[]),
      preload: false,
    );
    _queue = null;
    _queueKeys = const <String>[];
    _queueSongs = const <SongModel>[];
    _queueSourceLabel = '';
    _lastSavedIndex = null;
    _lastSavedPosition = Duration.zero;
    await _storage.clearResumePoint();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Play mode — the only place shuffle/loop may be changed
  // ------------------------------------------------------------------

  Future<void> _applyPlayMode() async {
    await player.setLoopMode(_loopMode);
    await player.setShuffleModeEnabled(_shuffleEnabled);
    // Regenerate the permutation for the freshly loaded source.
    if (_shuffleEnabled) await player.shuffle();
  }

  Future<void> toggleShuffle() async {
    _shuffleEnabled = !_shuffleEnabled;
    await player.setShuffleModeEnabled(_shuffleEnabled);
    // `shuffle()` permutes `shuffleOrder` (children order is untouched), so
    // turning shuffle off restores the original order. `initialIndex` keeps the
    // current track from jumping.
    if (_shuffleEnabled && hasQueue) {
      await player.shuffle();
    }
    await _storage.savePlayMode(shuffle: _shuffleEnabled, loop: _loopMode);
    notifyListeners();
  }

  /// off -> all -> one -> off
  Future<void> cycleLoopMode() async {
    _loopMode = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await player.setLoopMode(_loopMode);
    await _storage.savePlayMode(shuffle: _shuffleEnabled, loop: _loopMode);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Resume point
  // ------------------------------------------------------------------

  void _persistResumePoint(Duration position, {bool force = false}) {
    if (_queue == null) return;
    final index = player.currentIndex;
    if (index == null || index < 0 || index >= _queueKeys.length) return;

    if (!force) {
      final delta = position - _lastSavedPosition;
      if (delta < const Duration(seconds: 10)) return;
    }

    _lastSavedPosition = position;
    _lastSavedIndex = index;
    unawaited(
      _storage.saveResumePoint(
        index: index,
        position: position,
        songKey: _queueKeys[index],
      ),
    );
  }

  /// Called from the app lifecycle so a swipe-away never loses more than the
  /// last few seconds.
  Future<void> flushResumePoint() async {
    if (_queue == null) return;
    final index = player.currentIndex;
    if (index == null || index < 0 || index >= _queueKeys.length) return;
    await _storage.saveResumePoint(
      index: index,
      position: player.position,
      songKey: _queueKeys[index],
    );
  }

  /// Restores the previous queue after a cold start.
  ///
  /// Keys are cross-checked against the fresh library scan, so deleted files
  /// drop out instead of producing an unplayable queue.
  Future<bool> restoreSession(List<SongModel> library) async {
    final stored = await _storage.getQueue();
    if (stored.isEmpty) return false;

    final keys = reconcileKeys(stored, library);
    if (keys.isEmpty) {
      await _storage.clearResumePoint();
      return false;
    }

    final byKey = {for (final song in library) stableSongKey(song): song};
    final songs = <SongModel>[
      for (final key in keys)
        if (byKey[key] != null) byKey[key]!,
    ];
    if (songs.isEmpty) return false;

    final resume = await _storage.getResumePoint(keys);
    final index = resume?.index ?? 0;
    final position = resume?.position ?? Duration.zero;
    _queueSourceLabel = await _storage.getQueueSourceLabel();

    await playQueue(
      songs: songs,
      index: index.clamp(0, songs.length - 1),
      source: 'resume',
      label: _queueSourceLabel,
      autoPlay: false,
      initialPosition: position,
    );

    // Now that the v18 point is on disk, drop the MediaStore-id keys.
    await _storage.purgeLegacyResumeKeys();
    AppLog.d('Playback', 'session restored at $index (${position.inSeconds}s)');
    return true;
  }

  @override
  void dispose() {
    _positionSaveTimer?.cancel();
    _noisySubscription?.cancel();
    _interruptionSubscription?.cancel();
    _indexSubscription?.cancel();
    _stateSubscription?.cancel();
    player.dispose();
    super.dispose();
  }
}
