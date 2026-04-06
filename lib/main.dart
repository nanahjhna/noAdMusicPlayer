import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🚀 백그라운드 재생을 위한 임포트 추가
import 'package:just_audio_background/just_audio_background.dart';

import 'screens/home.dart';
import 'app_strings.dart';

Future<void> main() async {
  // 1. 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 🎵 백그라운드 오디오 서비스 초기화 (반드시 Supabase보다 먼저 혹은 직후에 호출)
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.handeveloper.noadmusic.channel.audio',
    androidNotificationChannelName: 'Music Playback',
    androidNotificationIcon: 'mipmap/ic_launcher',

    // 🚀 [핵심 수정]
    androidNotificationOngoing: false, // false로 해야 일시정지 시 알림을 밀어서 끌 수 있습니다.
    androidStopForegroundOnPause: true, // 일시정지 시 서비스 중단을 허용하여 'X' 버튼이 나타나게 유도합니다.
  );

  // 3. Supabase 초기화
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', // 실제 URL 입력 필요
    anonKey: 'YOUR_ANON_KEY', // 실제 Key 입력 필요
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // 다국어 설정을 위한 정적 메소드
  static void setLocale(BuildContext context, Locale locale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(locale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 기본 로케일 설정
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

      // 🌍 다국어 설정 유지
      locale: _locale,
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

      // 🎵 음악 앱 스타일 다크 테마 유지
      theme: ThemeData(
        useMaterial3: true,
        // 최신 UI 가이드 적용
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1DB954),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Manrope',
        // 폰트가 에셋에 등록되어 있어야 합니다.
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          surface: Color(0xFF121212),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 저장된 언어 설정 불러오기
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code') ?? 'ko';

    if (mounted) {
      MyApp.setLocale(context, Locale(code));
    }

    // ⏱ 최소 로딩 애니메이션 시간 확보
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 👉 메인 홈 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme
        .of(context)
        .primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 앱 로고 아이콘
            Icon(Icons.music_note_rounded, color: primary, size: 120),
            const SizedBox(height: 20),

            // 🎵 앱 이름 (다국어 처리)
            Text(
              AppStrings.get(context, 'app_name'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 50),

            // 로딩 인디케이터
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}