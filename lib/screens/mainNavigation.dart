import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<SongModel> songs = [];
  SongModel? currentSong;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    requestPermission();

    // 🎵 곡 종료 시 다음 곡 자동 재생
    _player.onPlayerComplete.listen((event) {
      playNextSong();
    });
  }

  // 🔐 권한 및 데이터 로드 로직
  Future<void> requestPermission() async {
    if (await Permission.audio.request().isGranted ||
        await Permission.storage.request().isGranted) {
      loadSongs();
    }
  }

  Future<void> loadSongs() async {
    final result = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    setState(() {
      songs = result;
    });
  }

  // ▶️ 재생 제어 로직
  Future<void> playMusic(SongModel song) async {
    await _player.stop();
    await _player.play(DeviceFileSource(song.data));
    setState(() {
      currentSong = song;
      isPlaying = true;
    });
  }

  void playNextSong() {
    if (songs.isEmpty || currentSong == null) return;
    int currentIndex = songs.indexWhere((s) => s.id == currentSong!.id);
    int nextIndex = (currentIndex + 1) % songs.length;
    playMusic(songs[nextIndex]);
  }

  Future<void> togglePlay() async {
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 전체를 DefaultTabController로 감싸 탭 기능을 활성화합니다.
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),

        // 2. MainNavigation에 있던 AppBar 설정을 이쪽으로 가져왔습니다.
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          centerTitle: false,
          title: const Text(
            "My Music Player",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.white)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings, color: Colors.white)),
          ],

          // 3. 상단 탭바 배치
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicatorColor: const Color(0xFF1DB954),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tabs: const [
                  Tab(text: "전체 곡"),
                  Tab(text: "플레이리스트"),
                  Tab(text: "아티스트"),
                  Tab(text: "앨범"),
                ],
              ),
            ),
          ),
        ),

        // 4. body를 TabBarView로 구성하여 탭마다 다른 화면을 보여줍니다.
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildSongList(), // 첫 번째 탭: 음악 목록
                const Center(child: Text("플레이리스트 화면", style: TextStyle(color: Colors.white))),
                const Center(child: Text("아티스트 화면", style: TextStyle(color: Colors.white))),
                const Center(child: Text("앨범 화면", style: TextStyle(color: Colors.white))),
              ],
            ),

            // 5. 미니 플레이어는 모든 탭에서 공통으로 보이도록 Stack의 최상단에 배치
            if (currentSong != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildMiniPlayer(),
              ),
          ],
        ),
      ),
    );
  }

  // --- 위젯 분리: 음악 목록 리스트 ---
  Widget _buildSongList() {
    if (songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      // 미니 플레이어 높이만큼 하단 여백 추가
      padding: EdgeInsets.only(bottom: currentSong != null ? 100 : 20),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: QueryArtworkWidget(
            id: song.id,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text(
            song.title,
            style: const TextStyle(color: Colors.white, overflow: TextOverflow.ellipsis),
          ),
          subtitle: Text(
            song.artist ?? "Unknown Artist",
            style: const TextStyle(color: Colors.grey),
          ),
          onTap: () => playMusic(song),
        );
      },
    );
  }

  // --- 위젯 분리: 미니 플레이어 ---
  Widget _buildMiniPlayer() {
    return Container(
      height: 70,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15)],
      ),
      child: Row(
        children: [
          QueryArtworkWidget(id: currentSong!.id, type: ArtworkType.AUDIO),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentSong!.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text(currentSong!.artist ?? "Unknown",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
            onPressed: togglePlay,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
            onPressed: playNextSong,
          ),
        ],
      ),
    );
  }
}