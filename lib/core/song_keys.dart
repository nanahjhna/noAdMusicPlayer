import 'package:on_audio_query/on_audio_query.dart';

/// Stable identity for a song on disk.
///
/// [SongModel.id] is a MediaStore row id. It changes whenever the device is
/// restored from backup, the SD card is re-formatted, the library is re-indexed
/// or the app is reinstalled. The previous version persisted that raw id for
/// playlists and the playback queue, so playlists silently emptied themselves
/// and "resume playback" pointed at an unrelated track.
///
/// `path | size | dateModified` survives all of those: the bytes are the same
/// file, so MediaStore must report the same path/size/mtime tuple.
String stableSongKey(SongModel song) {
  return '${song.data}|${song.size}|${song.dateModified ?? 0}';
}

/// Keys for a batch of songs.
List<String> stableSongKeys(Iterable<SongModel> songs) {
  return [for (final song in songs) stableSongKey(song)];
}

/// True when a persisted key was written by the old id-based schema.
///
/// Those are bare integers; the new format always contains at least two `|`
/// separators because a file path is involved.
bool isLegacyMediaStoreKey(String key) {
  if (key.isEmpty) return false;
  for (var i = 0; i < key.length; i++) {
    final code = key.codeUnitAt(i);
    if (code < 0x30 || code > 0x39) return false;
  }
  return true;
}

/// Rebuilds persisted keys against a freshly scanned library.
///
/// Handles two failure modes:
///  * legacy MediaStore ids — matched by [SongModel.id] and rewritten;
///  * files that legitimately disappeared — dropped.
List<String> reconcileKeys(List<String> stored, List<SongModel> library) {
  final byKey = <String, String>{};
  final byId = <int, String>{};
  for (final song in library) {
    final key = stableSongKey(song);
    byKey[key] = key;
    byId[song.id] = key;
  }

  final out = <String>[];
  for (final raw in stored) {
    final resolved = isLegacyMediaStoreKey(raw) ? byId[int.parse(raw)] : byKey[raw];
    if (resolved != null && !out.contains(resolved)) out.add(resolved);
  }
  return out;
}
