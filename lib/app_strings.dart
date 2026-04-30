import 'package:flutter/material.dart';

class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  // 1. UI에서 사용하는 AppStrings.of(context) 지원
  static AppStrings of(BuildContext context) {
    return AppStrings(Localizations.localeOf(context));
  }

  // 2. 모든 데이터를 하나의 static 맵으로 통합 (관리 편의성)
  static const Map<String, Map<String, String>> _data = {
    "ko": {
      'app_name': '광고 없는 음악',
      "close": "닫기",
      "no": "아니오",
      "yes": "예",
      "cancel": "취소",
      "confirm": "확인",
      "save": "저장",
      "delete": "삭제",
      "update": "수정",
      'unknownArtist': '알 수 없는 아티스트',
      'rename': '이름 변경',
      'addToPlaylist': '플레이리스트에 추가',
      'fileInfo': '파일 정보',
      'selectPlaylist': '플레이리스트 선택',
      'createNewPlaylist': '새 플레이리스트 생성',
      'addedTo': '에 추가되었습니다',
      'newPlaylistName': '새 플레이리스트 이름',
      'enterName': '이름을 입력하세요',
      'create': '생성',
      'renameSong': '곡 이름 변경',
      'change': '변경',
      'deleteSong': '곡 삭제',
      'deleteConfirm': '정말로 삭제하시겠습니까?',
      'searchHint': '곡명, 아티스트 검색',
      'exitApp': '앱 종료',
      'exitConfirm': '앱을 종료하시겠습니까?\n음악 재생이 중단됩니다.',
      "home": "홈",
      "tabMusic": "음악",
      "tabPlaylists": "플레이리스트",
      "tabSettings": "설정",
      "deletePlaylist": "플레이리스트 삭제",
      "deletePlaylistConfirm": "이 플레이리스트를 삭제하시겠습니까?",
      "noPlaylist": "생성된 플레이리스트가 없습니다.",
      "songsCount": "곡",
      "emptyPlaylist": "플레이리스트에 곡이 없습니다.",
      "playableSongs": "곡 재생 가능",
      "total": "총",
      "noPlayingSong": "재생 중인 곡이 없습니다.",
      "nowPlaying": "현재 재생 중",
      "noSongsFound": "곡이 없거나 로딩 중입니다.",
      'infoTitle': '제목',
      'infoArtist': '아티스트',
      'infoAlbum': '앨범',
      'infoFormat': '파일 형식',
      'infoSize': '크기',
      'infoPath': '경로',
      "languageSelect": "언어 선택",
      "languageSettings": "언어 설정",
      "korean": "한국어",
      "english": "English",
      "japanese": "日本語",
      "logout": "로그아웃",
    },
    "en": {
      'app_name': 'No Ad Music Player',
      "close": "Close",
      "no": "No",
      "yes": "Yes",
      "cancel": "Cancel",
      "confirm": "Confirm",
      "save": "Save",
      "delete": "Delete",
      "update": "Update",
      'unknownArtist': 'Unknown Artist',
      'rename': 'Rename',
      'addToPlaylist': 'Add to Playlist',
      'fileInfo': 'File Info',
      'selectPlaylist': 'Select Playlist',
      'createNewPlaylist': 'Create New Playlist',
      'addedTo': 'added to',
      'newPlaylistName': 'New Playlist Name',
      'enterName': 'Enter name',
      'create': 'Create',
      'renameSong': 'Rename Song',
      'change': 'Change',
      'deleteSong': 'Delete Song',
      'deleteConfirm': 'Are you sure you want to delete?',
      'searchHint': 'Search by title, artist',
      'exitApp': 'Exit App',
      'exitConfirm': 'Do you want to exit?\nPlayback will stop.',
      "home": "Home",
      "tabMusic": "Music",
      "tabPlaylists": "Playlists",
      "tabSettings": "Settings",
      "deletePlaylist": "Delete Playlist",
      "deletePlaylistConfirm": "Delete this playlist?",
      "noPlaylist": "No playlists created.",
      "songsCount": "Songs",
      "emptyPlaylist": "No songs in this playlist.",
      "playableSongs": "songs playable",
      "total": "Total",
      "noPlayingSong": "No song playing.",
      "nowPlaying": "NOW PLAYING",
      "noSongsFound": "No songs found or loading...",
      'infoTitle': 'Title',
      'infoArtist': 'Artist',
      'infoAlbum': 'Album',
      'infoFormat': 'Format',
      'infoSize': 'Size',
      'infoPath': 'Path',
      "languageSelect": "Select Language",
      "languageSettings": "Language Settings",
      "korean": "Korean",
      "english": "English",
      "japanese": "Japanese",
      "logout": "Logout",
    },
    "ja": {
      'app_name': '広告なし音楽',
      "close": "閉じる",
      "no": "いいえ",
      "yes": "はい",
      "cancel": "キャンセル",
      "confirm": "確認",
      "save": "保存",
      "delete": "削除",
      "update": "更新",
      'unknownArtist': '不明なアーティスト',
      'rename': '名前の変更',
      'addToPlaylist': 'プレイリストに追加',
      'fileInfo': 'ファイル情報',
      'selectPlaylist': 'プレイリストを選択',
      'createNewPlaylist': '新規作成',
      'addedTo': 'に追加されました',
      'newPlaylistName': 'プレイリスト名',
      'enterName': '名前を入力してください',
      'create': '作成',
      'renameSong': '曲名の変更',
      'change': '変更',
      'deleteSong': '曲の削除',
      'deleteConfirm': '本当に削除しますか？',
      'searchHint': '曲名、歌手で検索',
      'exitApp': 'アプリ終了',
      'exitConfirm': '終了しますか？\n再生が停止します。',
      "home": "ホーム",
      "tabMusic": "音楽",
      "tabPlaylists": "プレイリスト",
      "tabSettings": "設定",
      "deletePlaylist": "プレイリスト削除",
      "deletePlaylistConfirm": "削除しますか？",
      "noPlaylist": "プレイリストがありません。",
      "songsCount": "曲",
      "emptyPlaylist": "曲がありません。",
      "playableSongs": "曲 再生可能",
      "total": "合計",
      "noPlayingSong": "再生中の曲がありません。",
      "nowPlaying": "再生中",
      "noSongsFound": "曲がないか、読み込み中です。",
      'infoTitle': 'タイトル',
      'infoArtist': 'アーティスト',
      'infoAlbum': 'アルバム',
      'infoFormat': '形式',
      'infoSize': 'サイズ',
      'infoPath': 'パス',
      "languageSelect": "言語を選択",
      "languageSettings": "言語設定",
      "korean": "韓国語",
      "english": "英語",
      "japanese": "日本語",
      "logout": "ログアウト",
    }
  };

  // 3. 내부적으로 값을 찾아오는 헬퍼 (static get 방식과 Getter 방식 모두 대응)
  String _v(String key) {
    return _data[locale.languageCode]?[key] ?? _data['en']![key] ?? key;
  }

  // 4. [중요] 기존에 쓰시던 static get 메서드 (유지)
  static String get(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;
    return _data[lang]?[key] ?? _data['en']?[key] ?? key;
  }

  // 5. [중요] UI 코드(strings.변수명)를 위한 Getter들
  String get unknownArtist => _v('unknownArtist');
  String get rename => _getRename(); // 예약어 중복 방지 등을 위해 필요시 함수 호출 가능
  String get renameKey => _v('rename'); // 실제 사용
  String get addToPlaylist => _v('addToPlaylist');
  String get delete => _v('delete');
  String get fileInfo => _v('fileInfo');
  String get selectPlaylist => _v('selectPlaylist');
  String get createNewPlaylist => _v('createNewPlaylist');
  String get addedTo => _v('addedTo');
  String get newPlaylistName => _v('newPlaylistName');
  String get enterName => _v('enterName');
  String get cancel => _v('cancel');
  String get create => _v('create');
  String get renameSong => _v('renameSong');
  String get change => _v('change');
  String get deleteSong => _v('deleteSong');
  String get deleteConfirm => _v('deleteConfirm');
  String get searchHint => _v('searchHint');
  String get exitApp => _v('exitApp');
  String get exitConfirm => _getExitConfirm();
  String get yes => _v('yes');
  String get no => _v('no');
  String get tabMusic => _v('tabMusic');
  String get tabPlaylists => _v('tabPlaylists');
  String get tabSettings => _v('tabSettings');
  String get deletePlaylist => _v('deletePlaylist');
  String get deletePlaylistConfirm => _v('deletePlaylistConfirm');
  String get noPlaylist => _v('noPlaylist');
  String get songsCount => _v('songsCount');
  String get emptyPlaylist => _v('emptyPlaylist');
  String get playableSongs => _v('playableSongs');
  String get total => _v('total');
  String get noPlayingSong => _v('noPlayingSong');
  String get nowPlaying => _v('nowPlaying');
  String get close => _v('close');
  String get infoTitle => _v('infoTitle');
  String get infoArtist => _v('infoArtist');
  String get infoAlbum => _v('infoAlbum');
  String get infoFormat => _v('infoFormat');
  String get infoSize => _v('infoSize');
  String get infoPath => _v('infoPath');
  String get noSongsFound => _v('noSongsFound');
  String get renameLabel => _v('rename'); // rename이 getter로 쓰일 때

  // 헬퍼 함수 (필요시)
  String _getRename() => _v('rename');
  String _getExitConfirm() => _v('exitConfirm');
}