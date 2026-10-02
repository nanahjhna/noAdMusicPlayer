import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active locale and persists changes.
///
/// The old implementation reached into `MyApp`'s `State` with
/// `findAncestorStateOfType` from a settings screen several routes deep. An
/// [InheritedNotifier] is the supported way to do this, and it also means the
/// locale survives a hot restart without a `SplashScreen` round trip.
class AppScope extends InheritedNotifier<AppScopeState> {
  const AppScope({
    super.key,
    required AppScopeState state,
    required super.child,
  }) : super(notifier: state);

  static AppScopeState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree');
    return scope!.notifier!;
  }

  /// Reads the state without subscribing — for imperative calls such as
  /// writing the preference from a bottom sheet.
  static AppScopeState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static Future<void> setLanguage(BuildContext context, String languageCode) {
    return read(context).setLanguage(languageCode);
  }

  static Future<String> loadPersistedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language_code') ?? 'ko';
  }
}

class AppScopeState extends ChangeNotifier {
  AppScopeState(this._locale);

  Locale _locale;

  Locale get locale => _locale;

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    _locale = Locale(languageCode);
    notifyListeners();
  }
}
