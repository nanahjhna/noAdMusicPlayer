import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_strings.dart';
import '../core/design_system.dart';
import '../utils/logger.dart';

enum PermissionState { unknown, granted, denied, permanentlyDenied }

/// Blocking screen shown when the media permission is missing.
///
/// The previous build silently fell through to an empty black library with no
/// way to recover from inside the app — a dead end that also reads as a broken
/// app during store review.
class PermissionGate extends StatefulWidget {
  const PermissionGate({
    super.key,
    required this.onPermissionChanged,
    required this.onRetry,
  });

  final ValueChanged<bool> onPermissionChanged;
  final Future<void> Function() onRetry;

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  PermissionState _state = PermissionState.unknown;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    bool granted;
    try {
      granted = await _audioQuery.permissionsStatus();
    } catch (e) {
      AppLog.e('Permission', 'status check failed: $e');
      granted = false;
    }
    if (!mounted) return;
    setState(() {
      _state = granted ? PermissionState.granted : PermissionState.denied;
    });
    widget.onPermissionChanged(granted);
  }

  Future<void> _request() async {
    setState(() => _busy = true);
    bool granted = false;
    try {
      granted = await _audioQuery.permissionsRequest(retryRequest: true);
      if (!granted) {
        // Distinguish "tap again" from "go to system settings".
        final status = await _audioQuery.permissionsStatus();
        if (!status) {
          final permanently = await _audioQuery.permissionsRequest(
            retryRequest: true,
          );
          granted = permanently;
        }
      }
    } catch (e) {
      AppLog.e('Permission', 'request failed: $e');
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (granted) {
      await widget.onRetry();
    } else {
      await _refresh();
      if (mounted) setState(() => _state = PermissionState.denied);
    }
  }

  Future<void> _openSettings() async {
    setState(() => _busy = true);
    try {
      await openAppSettings();
    } catch (e) {
      AppLog.e('Permission', 'openAppSettings failed: $e');
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.library_music_rounded,
                    size: 40,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  strings.permissionRequired,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings.permissionBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_busy)
                  const CircularProgressIndicator(color: AppColors.accent)
                else ...[
                  SizedBox(
                    width: double.maxFinite,
                    child: FilledButton.icon(
                      onPressed: _request,
                      icon: const Icon(Icons.music_note_rounded, size: 20),
                      label: Text(strings.grantPermission),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (Platform.isAndroid || Platform.isIOS)
                    SizedBox(
                      width: double.maxFinite,
                      child: OutlinedButton.icon(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings_rounded, size: 20),
                        label: Text(strings.openSettings),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.surfaceHighest),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
