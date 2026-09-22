import 'package:flutter/foundation.dart';

/// 앱 공용 로거.
/// - 릴리스 빌드(kReleaseMode)에서는 아무것도 출력하지 않아,
///   상용 배포에 불필요한 콘솔 로그가 남지 않도록 한다.
/// - 디버그/프로파일 모드에서는 debugPrint로 출력한다.
class AppLog {
  AppLog._();

  static void d(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  static void e(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] ERROR: $message');
  }
}