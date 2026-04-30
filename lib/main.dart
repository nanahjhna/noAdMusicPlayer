import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'screens/mainHolder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎵 백그라운드 오디오 초기화
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.handeveloper.noadmusic.channel.audio',
    androidNotificationChannelName: 'Music Playback',
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidNotificationOngoing: false,
    androidStopForegroundOnPause: true,
  );

  // ☁️ Supabase 초기화 (⚠️ 실제 URL과 Key로 교체 필요)
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
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja')
      ],
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
    // 1. 저장된 언어 설정 불러오기
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code') ?? 'ko';

    if (mounted) {
      MyApp.setLocale(context, Locale(code));
    }

    // 2. 최소 로딩 시간 보장 (스플래시 체감)
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
            Icon(
                Icons.music_note_rounded,
                color: Theme.of(context).primaryColor,
                size: 120
            ),
            const SizedBox(height: 20),
            const Text(
                "No Ad Music Player",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}