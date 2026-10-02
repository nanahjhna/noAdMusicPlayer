import 'package:flutter/widgets.dart';

/// Localised UI copy.
///
/// Hand-rolled instead of gen-l10n because the app ships three locales and the
/// previous `app_strings.dart` had drifted: `app_name` had no getter at all
/// (dead key), `settingsScreen` hard-coded English, and several keys used by
/// the player were missing from some locales.
class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    return AppStrings(Localizations.localeOf(context));
  }

  static const Map<String, Map<String, String>> _data = {
    'ko': {
      'appName': '광고 없는 음악',
      'songs': '곡',
      'albums': '앨범',
      'artists': '아티스트',
      'playlists': '플레이리스트',
      'settings': '설정',
      'searchHint': '곡명, 아티스트 검색',
      'total': '총',
      'songsCount': '곡',
      'noSongsFound': '곡이 없습니다',
      'noResultsFor': '검색 결과가 없습니다',
      'unknownArtist': '알 수 없는 아티스트',
      'unknownAlbum': '알 수 없는 앨범',
      'noPlayingSong': '재생 중인 곡이 없습니다',
      'nowPlaying': '현재 재생 중',
      'upNext': '재생 대기',
      'queue': '재생 목록',
      'stop': '정지',
      'clearQueue': '재생 목록 비우기',
      'queueSource': '재생 중',
      'shuffle': '셔플',
      'repeat': '반복',
      'repeatAll': '전체 반복',
      'repeatOne': '한 곡 반복',
      'repeatOff': '반복 없음',
      'play': '재생',
      'pause': '일시정지',
      'previous': '이전 곡',
      'next': '다음 곡',
      'expandPlayer': '플레이어 펼치기',
      'collapsePlayer': '플레이어 접기',
      'rename': '이름 변경',
      'renameSong': '곡 이름 변경',
      'addToPlaylist': '플레이리스트에 추가',
      'removeFromPlaylist': '플레이리스트에서 제거',
      'delete': '삭제',
      'deleteSong': '곡 삭제',
      'deleteConfirm': '이 곡을 기기에서 삭제합니다. 되돌릴 수 없습니다.',
      'fileInfo': '파일 정보',
      'selectPlaylist': '플레이리스트 선택',
      'createNewPlaylist': '새 플레이리스트 만들기',
      'newPlaylistName': '새 플레이리스트 이름',
      'enterName': '이름을 입력하세요',
      'create': '만들기',
      'renamePlaylist': '플레이리스트 이름 변경',
      'deletePlaylist': '플레이리스트 삭제',
      'deletePlaylistConfirm': '이 플레이리스트를 삭제하시겠습니까?',
      'emptyPlaylist': '이 플레이리스트는 비어 있습니다',
      'missing': '파일 없음',
      'noPlaylist': '플레이리스트가 없습니다',
      'addedToPlaylist': '에 추가했습니다',
      'removedFromPlaylist': '에서 제거했습니다',
      'playlistExists': '이미 있는 이름입니다',
      'songAdded': '을(를) 추가했습니다',
      'invalidName': '이름에 / 또는 \\ 를 사용할 수 없습니다',
      'renameFailed': '이름을 변경하지 못했습니다',
      'deleteFailed': '파일을 삭제하지 못했습니다',
      'permissionRequired': '음악 파일 접근 권한이 필요합니다',
      'permissionBody':
          '기기에 저장된 음악을 읽으려면 권한이 필요합니다. 설정에서 앱 권한을 허용한 뒤 다시 시도해 주세요.',
      'grantPermission': '권한 허용',
      'openSettings': '앱 설정 열기',
      'tryAgain': '다시 시도',
      'scanFailed': '음악 파일을 불러오지 못했습니다',
      'emptyLibrary': '음악 파일이 없습니다',
      'emptyLibraryBody': '기기에 음악 파일을 추가한 뒤 새로고침하세요',
      'refresh': '새로고침',
      'exitApp': '앱 종료',
      'exitConfirm': '앱을 종료하시겠습니까?\n음악 재생이 중단됩니다.',
      'no': '아니오',
      'yes': '예',
      'cancel': '취소',
      'close': '닫기',
      'confirm': '확irm',
      'done': '완료',
      'infoTitle': '제목',
      'infoArtist': '아티스트',
      'infoAlbum': '앨범',
      'infoFormat': '파일 형식',
      'infoSize': '크기',
      'infoPath': '경로',
      'infoDuration': '길이',
      'languageSettings': '언어 설정',
      'languageSelect': '언어 선택',
      'korean': '한국어',
      'english': 'English',
      'japanese': '日本語',
      'about': '정보',
      'appVersion': '앱 버전',
      'playback': '재생 설정',
      'gaplessNote': 'Mp3 · M4a · Flac · Wav · Ogg 지원',
    },
    'en': {
      'appName': 'No Ad Music',
      'songs': 'Songs',
      'albums': 'Albums',
      'artists': 'Artists',
      'playlists': 'Playlists',
      'settings': 'Settings',
      'searchHint': 'Search title, artist',
      'total': 'Total',
      'songsCount': 'songs',
      'noSongsFound': 'No songs',
      'noResultsFor': 'No results for',
      'unknownArtist': 'Unknown Artist',
      'unknownAlbum': 'Unknown Album',
      'noPlayingSong': 'Nothing playing',
      'nowPlaying': 'NOW PLAYING',
      'upNext': 'Up next',
      'queue': 'Queue',
      'stop': 'Stop',
      'clearQueue': 'Clear queue',
      'queueSource': 'Playing from',
      'shuffle': 'Shuffle',
      'repeat': 'Repeat',
      'repeatAll': 'Repeat all',
      'repeatOne': 'Repeat one',
      'repeatOff': 'Repeat off',
      'play': 'Play',
      'pause': 'Pause',
      'previous': 'Previous',
      'next': 'Next',
      'expandPlayer': 'Expand player',
      'collapsePlayer': 'Collapse player',
      'rename': 'Rename',
      'renameSong': 'Rename song',
      'addToPlaylist': 'Add to playlist',
      'removeFromPlaylist': 'Remove from playlist',
      'delete': 'Delete',
      'deleteSong': 'Delete song',
      'deleteConfirm':
          'This removes the file from your device. This cannot be undone.',
      'fileInfo': 'File info',
      'selectPlaylist': 'Select playlist',
      'createNewPlaylist': 'New playlist',
      'newPlaylistName': 'New playlist name',
      'enterName': 'Enter a name',
      'create': 'Create',
      'renamePlaylist': 'Rename playlist',
      'deletePlaylist': 'Delete playlist',
      'deletePlaylistConfirm': 'Delete this playlist?',
      'emptyPlaylist': 'This playlist is empty',
      'missing': 'missing',
      'noPlaylist': 'No playlists yet',
      'addedToPlaylist': 'added to',
      'removedFromPlaylist': 'removed from',
      'playlistExists': 'That name is already taken',
      'songAdded': 'added',
      'invalidName': 'A name cannot contain / or \\',
      'renameFailed': 'Could not rename the file',
      'deleteFailed': 'Could not delete the file',
      'permissionRequired': 'Music access needed',
      'permissionBody':
          'To read the music stored on this device we need your permission. Allow it in app settings, then try again.',
      'grantPermission': 'Grant permission',
      'openSettings': 'Open app settings',
      'tryAgain': 'Try again',
      'scanFailed': 'Could not load your music',
      'emptyLibrary': 'No music found',
      'emptyLibraryBody': 'Add music files to this device, then refresh',
      'refresh': 'Refresh',
      'exitApp': 'Exit app',
      'exitConfirm': 'Exit the app?\nPlayback will stop.',
      'no': 'No',
      'yes': 'Yes',
      'cancel': 'Cancel',
      'close': 'Close',
      'confirm': 'Confirm',
      'done': 'Done',
      'infoTitle': 'Title',
      'infoArtist': 'Artist',
      'infoAlbum': 'Album',
      'infoFormat': 'Format',
      'infoSize': 'Size',
      'infoPath': 'Path',
      'infoDuration': 'Duration',
      'languageSettings': 'Language',
      'languageSelect': 'Select language',
      'korean': '한국어',
      'english': 'English',
      'japanese': '日本語',
      'about': 'About',
      'appVersion': 'Version',
      'playback': 'Playback',
      'gaplessNote': 'Mp3 · M4a · Flac · Wav · Ogg',
    },
    'ja': {
      'appName': '広告なし音楽',
      'songs': '曲',
      'albums': 'アルバム',
      'artists': 'アーティスト',
      'playlists': 'プレイリスト',
      'settings': '設定',
      'searchHint': '曲名、アーティストを検索',
      'total': '合計',
      'songsCount': '曲',
      'noSongsFound': '曲がありません',
      'noResultsFor': '検索結果がありません',
      'unknownArtist': '不明なアーティスト',
      'unknownAlbum': '不明なアルバム',
      'noPlayingSong': '再生中の曲がありません',
      'nowPlaying': '再生中',
      'upNext': '次の曲',
      'queue': 'キュー',
      'stop': '停止',
      'clearQueue': 'キューを空にする',
      'queueSource': '再生元',
      'shuffle': 'シャッフル',
      'repeat': 'リピート',
      'repeatAll': '全曲リピート',
      'repeatOne': '1曲リピート',
      'repeatOff': 'リピートなし',
      'play': '再生',
      'pause': '一時停止',
      'previous': '前の曲',
      'next': '次の曲',
      'expandPlayer': 'プレイヤーを開く',
      'collapsePlayer': 'プレイヤーを閉じる',
      'rename': '名前を変更',
      'renameSong': '曲名を変更',
      'addToPlaylist': 'プレイリストに追加',
      'removeFromPlaylist': 'プレイリストから削除',
      'delete': '削除',
      'deleteSong': '曲を削除',
      'deleteConfirm': '端末からファイルを削除します。元に戻せません。',
      'fileInfo': 'ファイル情報',
      'selectPlaylist': 'プレイリストを選択',
      'createNewPlaylist': '新しいプレイリスト',
      'newPlaylistName': 'プレイリスト名',
      'enterName': '名前を入力',
      'create': '作成',
      'renamePlaylist': 'プレイリスト名を変更',
      'deletePlaylist': 'プレイリストを削除',
      'deletePlaylistConfirm': 'このプレイリストを削除しますか？',
      'emptyPlaylist': 'このプレイリストは空です',
      'missing': 'ファイルなし',
      'noPlaylist': 'プレイリストがありません',
      'addedToPlaylist': 'に追加しました',
      'removedFromPlaylist': 'から削除しました',
      'playlistExists': 'その名前は既にあります',
      'songAdded': 'を追加しました',
      'invalidName': '名前に / または \\ は使えません',
      'renameFailed': '名前を変更できませんでした',
      'deleteFailed': 'ファイルを削除できませんでした',
      'permissionRequired': '音楽へのアクセス権が必要です',
      'permissionBody':
          '端末の音楽を読み取るには権限が必要です。設定で許可してから再試行してください。',
      'grantPermission': '権限を許可',
      'openSettings': 'アプリ設定を開く',
      'tryAgain': '再試行',
      'scanFailed': '音楽を読み込めませんでした',
      'emptyLibrary': '音楽が見つかりません',
      'emptyLibraryBody': '端末に音楽を追加してから更新してください',
      'refresh': '更新',
      'exitApp': 'アプリを終了',
      'exitConfirm': 'アプリを終了しますか？\n再生が停止します。',
      'no': 'いいえ',
      'yes': 'はい',
      'cancel': 'キャンセル',
      'close': '閉じる',
      'confirm': '確認',
      'done': '完了',
      'infoTitle': 'タイトル',
      'infoArtist': 'アーティスト',
      'infoAlbum': 'アルバム',
      'infoFormat': '形式',
      'infoSize': 'サイズ',
      'infoPath': 'パス',
      'infoDuration': '長さ',
      'languageSettings': '言語設定',
      'languageSelect': '言語を選択',
      'korean': '韓国語',
      'english': '英語',
      'japanese': '日本語',
      'about': '情報',
      'appVersion': 'バージョン',
      'playback': '再生',
      'gaplessNote': 'Mp3 · M4a · Flac · Wav · Ogg',
    },
  };

  /// Falls back to English, then to the key itself, so a missing translation
  /// shows up as `someKey` rather than an empty string.
  String v(String key) =>
      _data[locale.languageCode]?[key] ?? _data['en']?[key] ?? key;

  static String get(BuildContext context, String key) =>
      AppStrings.of(context).v(key);

  String get appName => v('appName');
  String get songs => v('songs');
  String get albums => v('albums');
  String get artists => v('artists');
  String get playlists => v('playlists');
  String get settings => v('settings');
  String get searchHint => v('searchHint');
  String get total => v('total');
  String get songsCount => v('songsCount');
  String get noSongsFound => v('noSongsFound');
  String get noResultsFor => v('noResultsFor');
  String get unknownArtist => v('unknownArtist');
  String get unknownAlbum => v('unknownAlbum');
  String get noPlayingSong => v('noPlayingSong');
  String get nowPlaying => v('nowPlaying');
  String get upNext => v('upNext');
  String get queue => v('queue');
  String get stop => v('stop');
  String get clearQueue => v('clearQueue');
  String get queueSource => v('queueSource');
  String get shuffle => v('shuffle');
  String get repeat => v('repeat');
  String get repeatAll => v('repeatAll');
  String get repeatOne => v('repeatOne');
  String get repeatOff => v('repeatOff');
  String get play => v('play');
  String get pause => v('pause');
  String get previous => v('previous');
  String get next => v('next');
  String get expandPlayer => v('expandPlayer');
  String get collapsePlayer => v('collapsePlayer');
  String get rename => v('rename');
  String get renameSong => v('renameSong');
  String get addToPlaylist => v('addToPlaylist');
  String get removeFromPlaylist => v('removeFromPlaylist');
  String get delete => v('delete');
  String get deleteSong => v('deleteSong');
  String get deleteConfirm => v('deleteConfirm');
  String get fileInfo => v('fileInfo');
  String get selectPlaylist => v('selectPlaylist');
  String get createNewPlaylist => v('createNewPlaylist');
  String get newPlaylistName => v('newPlaylistName');
  String get enterName => v('enterName');
  String get create => v('create');
  String get renamePlaylist => v('renamePlaylist');
  String get deletePlaylist => v('deletePlaylist');
  String get deletePlaylistConfirm => v('deletePlaylistConfirm');
  String get emptyPlaylist => v('emptyPlaylist');
  String get missing => v('missing');
  String get noPlaylist => v('noPlaylist');
  String get addedToPlaylist => v('addedToPlaylist');
  String get removedFromPlaylist => v('removedFromPlaylist');
  String get playlistExists => v('playlistExists');
  String get songAdded => v('songAdded');
  String get invalidName => v('invalidName');
  String get renameFailed => v('renameFailed');
  String get deleteFailed => v('deleteFailed');
  String get permissionRequired => v('permissionRequired');
  String get permissionBody => v('permissionBody');
  String get grantPermission => v('grantPermission');
  String get openSettings => v('openSettings');
  String get tryAgain => v('tryAgain');
  String get scanFailed => v('scanFailed');
  String get emptyLibrary => v('emptyLibrary');
  String get emptyLibraryBody => v('emptyLibraryBody');
  String get refresh => v('refresh');
  String get exitApp => v('exitApp');
  String get exitConfirm => v('exitConfirm');
  String get no => v('no');
  String get yes => v('yes');
  String get cancel => v('cancel');
  String get close => v('close');
  String get confirm => v('confirm');
  String get done => v('done');
  String get infoTitle => v('infoTitle');
  String get infoArtist => v('infoArtist');
  String get infoAlbum => v('infoAlbum');
  String get infoFormat => v('infoFormat');
  String get infoSize => v('infoSize');
  String get infoPath => v('infoPath');
  String get infoDuration => v('infoDuration');
  String get languageSettings => v('languageSettings');
  String get languageSelect => v('languageSelect');
  String get korean => v('korean');
  String get english => v('english');
  String get japanese => v('japanese');
  String get about => v('about');
  String get appVersion => v('appVersion');
  String get playback => v('playback');
  String get gaplessNote => v('gaplessNote');
}
