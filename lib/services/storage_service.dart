import 'dart:convert';

import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted playback + library state.
///
/// Key granularity is deliberate: the playback queue can run to tens of
/// thousands of entries, so it is written only when the queue actually changes
/// while the resume point is written frequently (two ints plus one string).
class StorageService {
  StorageService({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  static const String _kResumeIndex = 'resume_index';
  static const String _kResumePosition = 'resume_position';
  static const String _kResumeSongKey = 'resume_song_key';
  static const String _kShuffle = 'play_shuffle';
  static const String _kLoopMode = 'play_loop_mode';
  static const String _kQueue = 'play_queue_keys';
  static const String _kQueueSource = 'play_queue_source';
  static const String _kPlaylists = 'playlists_v2';
  static const String _kPlaylistsLegacy = 'playlists';
  static const String _kLanguage = 'language_code';

  // Pre-v18 schema, written with raw MediaStore row ids. Purged once the new
  // resume point has been written successfully.
  static const String _kLegacyIndex = 'last_index';
  static const String _kLegacyPosition = 'last_position';
  static const String _kLegacySongId = 'last_song_id';
  static const String _kLegacyQueue = 'last_queue';

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  // ------------------------------------------------------------------
  // Playback queue + resume point
  // ------------------------------------------------------------------

  /// Ordered stable keys of the loaded queue. Written only on queue change.
  Future<void> saveQueue(List<String> keys, String sourceLabel) async {
    final prefs = await _prefs;
    await prefs.setString(_kQueue, jsonEncode(keys));
    await prefs.setString(_kQueueSource, sourceLabel);
  }

  Future<List<String>> getQueue() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kQueue);
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<String> getQueueSourceLabel() async {
    final prefs = await _prefs;
    return prefs.getString(_kQueueSource) ?? '';
  }

  /// Resume point inside [queueKeys]. [songKey] is a redundant guard: if the
  /// queue was re-ordered or trimmed, the index alone is not trustworthy.
  Future<({int index, Duration position})?> getResumePoint(
    List<String> queueKeys,
  ) async {
    if (queueKeys.isEmpty) return null;
    final prefs = await _prefs;

    final index = prefs.getInt(_kResumeIndex);
    final positionMs = prefs.getInt(_kResumePosition) ?? 0;
    final songKey = prefs.getString(_kResumeSongKey);

    if (index != null && index >= 0 && index < queueKeys.length) {
      if (songKey == null || songKey == queueKeys[index]) {
        return (index: index, position: Duration(milliseconds: positionMs));
      }
    }
    return null;
  }

  Future<void> saveResumePoint({
    required int index,
    required Duration position,
    required String songKey,
  }) async {
    final prefs = await _prefs;
    await prefs.setInt(_kResumeIndex, index);
    await prefs.setInt(_kResumePosition, position.inMilliseconds);
    await prefs.setString(_kResumeSongKey, songKey);
  }

  Future<void> clearResumePoint() async {
    final prefs = await _prefs;
    await prefs.remove(_kResumeIndex);
    await prefs.remove(_kResumePosition);
    await prefs.remove(_kResumeSongKey);
  }

  // ------------------------------------------------------------------
  // Play mode
  // ------------------------------------------------------------------

  Future<void> savePlayMode({required bool shuffle, required LoopMode loop}) async {
    final prefs = await _prefs;
    await prefs.setBool(_kShuffle, shuffle);
    await prefs.setInt(_kLoopMode, loop.index);
  }

  Future<({bool shuffle, LoopMode loop})> getPlayMode() async {
    final prefs = await _prefs;
    final rawIndex = prefs.getInt(_kLoopMode) ?? LoopMode.off.index;
    // Guard against a value persisted by a different just_audio build.
    final loop = rawIndex >= 0 && rawIndex < LoopMode.values.length
        ? LoopMode.values[rawIndex]
        : LoopMode.off;
    return (shuffle: prefs.getBool(_kShuffle) ?? false, loop: loop);
  }

  // ------------------------------------------------------------------
  // Playlists
  // ------------------------------------------------------------------

  /// Playlists keyed by name, values are ordered stable song keys.
  ///
  /// Reads the v2 schema and transparently upgrades the legacy id-based one so
  /// existing installs keep their playlists.
  Future<Map<String, List<String>>> getPlaylists() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kPlaylists);
    if (raw != null) {
      final parsed = _decodePlaylists(raw);
      if (parsed != null) return parsed;
    }
    final legacy = prefs.getString(_kPlaylistsLegacy);
    if (legacy == null) return <String, List<String>>{};
    return _decodePlaylists(legacy) ?? <String, List<String>>{};
  }

  Map<String, List<String>>? _decodePlaylists(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (name, value) => MapEntry(name, List<String>.from(value as List)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> savePlaylists(Map<String, List<String>> playlists) async {
    final prefs = await _prefs;
    await prefs.setString(_kPlaylists, jsonEncode(playlists));
  }

  /// Creates [name] if missing and appends [keys], skipping duplicates.
  Future<void> addSongsToPlaylist(String name, List<String> keys) async {
    if (name.trim().isEmpty) return;
    final playlists = await getPlaylists();
    final list = playlists.putIfAbsent(name, () => <String>[]);
    for (final key in keys) {
      if (!list.contains(key)) list.add(key);
    }
    await savePlaylists(playlists);
  }

  Future<void> removeSongFromPlaylist(String name, String key) async {
    final playlists = await getPlaylists();
    playlists[name]?.remove(key);
    if (playlists[name]?.isEmpty ?? false) playlists.remove(name);
    await savePlaylists(playlists);
  }

  /// Moves the item at [oldIndex] to [newIndex] within one playlist.
  Future<void> movePlaylistItem(String name, int oldIndex, int newIndex) async {
    final playlists = await getPlaylists();
    final list = playlists[name];
    if (list == null) return;
    if (oldIndex < 0 || oldIndex >= list.length) return;
    final clamped = newIndex.clamp(0, list.length - 1);
    if (clamped == oldIndex) return;
    final item = list.removeAt(oldIndex);
    list.insert(clamped, item);
    await savePlaylists(playlists);
  }

  Future<void> renamePlaylist(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return;
    final playlists = await getPlaylists();
    if (!playlists.containsKey(oldName)) return;
    if (playlists.containsKey(trimmed)) {
      // Merge into the existing playlist rather than silently clobbering it.
      for (final key in playlists[oldName]!) {
        if (!playlists[trimmed]!.contains(key)) {
          playlists[trimmed]!.add(key);
        }
      }
      playlists.remove(oldName);
    } else {
      playlists[trimmed] = playlists.remove(oldName)!;
    }
    await savePlaylists(playlists);
  }

  Future<void> deletePlaylist(String name) async {
    final playlists = await getPlaylists();
    playlists.remove(name);
    await savePlaylists(playlists);
  }

  // ------------------------------------------------------------------
  // Settings
  // ------------------------------------------------------------------

  Future<String> getLanguageCode() async {
    final prefs = await _prefs;
    return prefs.getString(_kLanguage) ?? 'ko';
  }

  Future<void> setLanguageCode(String code) async {
    final prefs = await _prefs;
    await prefs.setString(_kLanguage, code);
  }

  // ------------------------------------------------------------------
  // One-time cleanup of the pre-v18 schema
  // ------------------------------------------------------------------

  /// Drops the old MediaStore-id keys once the new resume point is safely on
  /// disk, so a later crash cannot fall back to them.
  Future<void> purgeLegacyResumeKeys() async {
    final prefs = await _prefs;
    await prefs.remove(_kLegacyIndex);
    await prefs.remove(_kLegacyPosition);
    await prefs.remove(_kLegacySongId);
    await prefs.remove(_kLegacyQueue);
  }
}
