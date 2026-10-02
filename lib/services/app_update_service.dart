import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/app_strings.dart';
import '../core/design_system.dart';
import '../utils/logger.dart';

/// Result of an update probe.
enum UpdateStatus {
  /// Play has a newer release the user can install.
  available,

  /// The installed build is current.
  upToDate,

  /// The app was not installed from Play (sideloaded APK, debug build, or a
  /// platform without Play Core), so there is nothing to offer.
  unavailable,

  /// The check itself failed — offline, Play Core error.
  failed,
}

/// Google Play in-app update.
///
/// Play decides *whether* an update exists: `checkForUpdate` asks the store, so
/// the app never has to know the published version itself. Only `pubspec.yaml`'s
/// `version:` matters for what users already have; the server side lives in the
/// Play Console.
///
/// An immediate update (blocking, Play manages the download and the restart)
/// is used rather than a flexible one: a music player that is updated while the
/// user has a queue loaded risks losing the queue, so the restart should be
/// deliberate.
class AppUpdateService {
  const AppUpdateService();

  Future<UpdateStatus> check() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return UpdateStatus.unavailable;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final result = await InAppUpdate.checkForUpdate();
      final available = result.updateAvailability == UpdateAvailability
          .updateAvailable;
      if (!available) return UpdateStatus.upToDate;

      AppLog.d('Update', 'update available (current ${info.version}+${info.buildNumber})');
      return UpdateStatus.available;
    } catch (e) {
      AppLog.e('Update', 'check failed: $e');
      return UpdateStatus.failed;
    }
  }

  /// Runs the download + install flow. Blocking, so the app is replaced.
  Future<void> performUpdate() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      AppLog.e('Update', 'performImmediateUpdate failed: $e');
    }
  }
}

/// Shows the "update available" dialog and returns true when the user started
/// the install. No-op when the status is anything other than [available].
Future<bool> promptUpdateIfAvailable(
  BuildContext context,
  AppUpdateService service, {
  required UpdateStatus status,
}) async {
  if (status != UpdateStatus.available) return false;

  final strings = AppStrings.of(context);
  final start = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.updateAvailable),
      content: Text(strings.updateAvailableBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            strings.updateLater,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(strings.updateNow, style: const TextStyle(color: AppColors.accent)),
        ),
      ],
    ),
  );

  if (start != true) return false;
  await service.performUpdate();
  return true;
}

/// One-line confirmation used by the manual check in settings.
void showUpdateStatusSnackBar(BuildContext context, UpdateStatus status) {
  final strings = AppStrings.of(context);
  final message = switch (status) {
    UpdateStatus.upToDate => strings.upToDate,
    UpdateStatus.failed => strings.updateCheckFailed,
    UpdateStatus.available => strings.updateAvailable,
    UpdateStatus.unavailable => strings.updateCheckFailed,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surfaceHigh,
      ),
    );
}