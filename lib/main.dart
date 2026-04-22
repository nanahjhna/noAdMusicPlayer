import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';

// 새롭게 분리할 탭 관리 파일 임포트
import 'screens/mainHolder.dart';
import 'app_strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎵 백그라운드 오디오 초기화 (수정된 부분)
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.handeveloper.noadmusic.channel.audio',
    androidNotificationChannelName: 'Music Playback',
    androidNotificationIcon: 'mipmap/ic_launcher',

    // 🚀 강제 종료(Task 제거) 시 음악을 멈추게 하는 핵심 설정들
    androidNotificationOngoing: false,      // 알림 스와이프 삭제 허용
    androidStopForegroundOnPause: true,    // 일시정지 시 서비스 중단 허용

    // 이 옵션은 패키지에 따라 지원 여부가 다를 수 있지만,
    // 기본적으로 'false' 설정들이 시스템이 앱 프로세스와 함께 서비스를 종료하도록 유도합니다.
  );

  // ☁️ Supabase 초기화 (실제 값 입력 필요)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_ANON_KEY',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale locale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(locale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ko');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'No Ad Music',
      locale: _locale,
      supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1DB954),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          surface: Color(0xFF121212),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// 스플래시 화면 (로딩 후 MainHolder로 이동)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code') ?? 'ko';

    if (mounted) MyApp.setLocale(context, Locale(code));

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainHolder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note_rounded, color: Theme
                .of(context)
                .primaryColor, size: 120),
            const SizedBox(height: 20),
            const Text("No Ad Music Player",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}