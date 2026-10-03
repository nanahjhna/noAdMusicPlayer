import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/app_scope.dart';
import '../core/app_strings.dart';
import '../core/design_system.dart';
import '../services/app_update_service.dart';
import '../services/banner_ad_service.dart';

/// Settings.
///
/// The previous build hard-coded English labels and a literal `"1.0.0"`
/// version while `package_info_plus` sat unused in pubspec — so the About row
/// could never be right after the first release bump.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onRefreshLibrary});

  final Future<void> Function() onRefreshLibrary;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const AppUpdateService _updates = AppUpdateService();

  String _version = '';
  String _build = '';
  bool _checkingUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = '${info.version}+${info.buildNumber}';
        _build = info.packageName;
      });
    } catch (_) {
      // Leave blank rather than showing a wrong number.
    }
  }

  Future<void> _checkForUpdates() async {
    if (_checkingUpdates) return;
    setState(() => _checkingUpdates = true);

    final status = await _updates.check();
    if (!mounted) return;
    setState(() => _checkingUpdates = false);

    // An available update gets the dialog; everything else reports inline so a
    // failed or sideloaped install is visible instead of looking like silence.
    final started = await promptUpdateIfAvailable(
      context,
      _updates,
      status: status,
    );
    if (!started && mounted) showUpdateStatusSnackBar(context, status);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      children: [
        Container(
          color: AppColors.background,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            MediaQuery.paddingOf(context).top + AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Text(
            strings.settings,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              _Section(
                title: strings.languageSettings,
                children: [
                  ListTile(
                    leading: const _Leading(icon: Icons.language_rounded),
                    title: Text(
                      strings.languageSelect,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => _showLanguagePicker(context),
                  ),
                ],
              ),
              _Section(
                title: strings.playback,
                children: [
                  ListTile(
                    leading: const _Leading(icon: Icons.refresh_rounded),
                    title: Text(
                      strings.refresh,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      strings.emptyLibraryBody,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    onTap: widget.onRefreshLibrary,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Text(
                      strings.gaplessNote,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              _Section(
                title: strings.about,
                children: [
                  ListTile(
                    leading: const _Leading(icon: Icons.info_outline_rounded),
                    title: Text(
                      strings.appVersion,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    trailing: Text(
                      _version.isEmpty ? '—' : _version,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                  if (_build.isNotEmpty)
                    ListTile(
                      leading: const _Leading(icon: Icons.tag_rounded),
                      title: Text(
                        'Package',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      trailing: Text(
                        _build,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ListTile(
                    leading: const _Leading(icon: Icons.system_update_rounded),
                    title: Text(
                      strings.checkForUpdates,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    trailing: _checkingUpdates
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textTertiary,
                          ),
                    onTap: _checkingUpdates ? null : _checkForUpdates,
                  ),
                ],
              ),
              const SettingsBannerAd(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final strings = AppStrings.of(context);
    final current = Localizations.localeOf(context).languageCode;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighest,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              strings.languageSelect,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _option(sheetContext, strings.korean, 'ko', current),
            _option(sheetContext, strings.english, 'en', current),
            _option(sheetContext, strings.japanese, 'ja', current),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (selected == null || !context.mounted) return;
    await AppScope.setLanguage(context, selected);
  }

  Widget _option(BuildContext context, String label, String code, String current) {
    final selected = code == current;
    return ListTile(
      onTap: () => Navigator.pop(context, code),
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? AppColors.accent : AppColors.textTertiary,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.accent : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 20, color: AppColors.textPrimary),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
