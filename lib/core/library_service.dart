import 'dart:io';

import 'package:on_audio_query/on_audio_query.dart';

import '../utils/logger.dart';

/// Result of a library scan.
class LibrarySnapshot {
  const LibrarySnapshot({
    required this.songs,
    required this.albums,
    required this.artists,
  });

  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
}

/// Reads the device media store and performs file mutations.
class LibraryService {
  LibraryService({OnAudioQuery? audioQuery})
      : _audioQuery = audioQuery ?? OnAudioQuery();

  final OnAudioQuery _audioQuery;

  static const Set<String> supportedExtensions = {
    'mp3',
    'm4a',
    'aac',
    'flac',
    'wav',
    'ogg',
    'opus',
    'wma',
    'alac',
  };

  /// Tracks shorter than this are ringtone/alarm/notification artefacts that
  /// only pollute the library.
  static const int minimumDurationMs = 30000;

  /// One scan pass: songs + albums + artists, all filtered to real music.
  ///
  /// on_audio_query exposes no artwork cache control, so the memory ceiling
  /// comes from `SongArtwork` instead: a fixed pixel size and
  /// `FilterQuality.low` per thumbnail.
  Future<LibrarySnapshot> scan() async {
    final rawSongs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    final songs = rawSongs.where(_isPlayable).toList(growable: false);

    final albums = await _safeQuery(
      () => _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      ),
      'albums',
    );

    final artists = await _safeQuery(
      () => _audioQuery.queryArtists(
        sortType: ArtistSortType.ARTIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      ),
      'artists',
    );

    AppLog.d(
      'Library',
      'scan: ${songs.length} songs / ${albums.length} albums / ${artists.length} artists',
    );
    return LibrarySnapshot(songs: songs, albums: albums, artists: artists);
  }

  bool _isPlayable(SongModel song) {
    if ((song.duration ?? 0) < minimumDurationMs) return false;
    return supportedExtensions.contains(song.fileExtension.toLowerCase());
  }

  Future<List<T>> _safeQuery<T>(
    Future<List<T>> Function() query,
    String label,
  ) async {
    try {
      return await query();
    } catch (e) {
      AppLog.e('Library', 'query $label failed: $e');
      return const [];
    }
  }

  /// Songs belonging to an album, in disc/track order where the tags allow it.
  List<SongModel> songsOfAlbum(List<SongModel> library, AlbumModel album) {
    final id = album.id;
    final matched = library.where((s) => s.albumId == id).toList();
    matched.sort(_compareByTrackThenTitle);
    return matched;
  }

  List<SongModel> songsOfArtist(List<SongModel> library, ArtistModel artist) {
    final id = artist.id;
    final matched = library.where((s) => s.artistId == id).toList();
    matched.sort(_compareByAlbumThenTrack);
    return matched;
  }

  int _compareByTrackThenTitle(SongModel a, SongModel b) {
    final ta = a.track ?? 1 << 20;
    final tb = b.track ?? 1 << 20;
    if (ta != tb) return ta.compareTo(tb);
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  int _compareByAlbumThenTrack(SongModel a, SongModel b) {
    final aa = (a.album ?? '').toLowerCase();
    final ba = (b.album ?? '').toLowerCase();
    if (aa != ba) return aa.compareTo(ba);
    return _compareByTrackThenTitle(a, b);
  }

  // ------------------------------------------------------------------
  // File operations
  // ------------------------------------------------------------------

  /// Renames a track, preserving its extension.
  Future<String?> renameSong(SongModel song, String newTitle) async {
    final clean = newTitle.trim();
    if (clean.isEmpty) return 'empty';
    if (clean == song.title) return null;
    if (clean.contains('/') || clean.contains('\\')) return 'invalid';

    try {
      final file = File(song.data);
      if (!await file.exists()) return 'missing';
      final extension = song.fileExtension;
      final target = File('${file.parent.path}${Platform.pathSeparator}$clean.$extension');
      if (await target.exists()) return 'exists';
      await file.rename(target.path);
      return null;
    } catch (e) {
      AppLog.e('Library', 'rename failed: $e');
      return 'error';
    }
  }

  Future<bool> deleteSong(SongModel song) async {
    try {
      final file = File(song.data);
      if (!await file.exists()) return false;
      await file.delete();
      return true;
    } catch (e) {
      AppLog.e('Library', 'delete failed: $e');
      return false;
    }
  }
}
