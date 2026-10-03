import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/design_system.dart';
import '../utils/logger.dart';

/// Banner placement for the settings screen.
///
/// The slot owns the [BannerAd] lifecycle so the widget can stay dumb.
/// Ads are loaded only on Android/iOS and the real AdMob banner unit ID
/// is used in all build modes.
class BannerAdSlot {
  BannerAdSlot();

  /// AdMob banner unit ID.
  static const String bannerAdUnitId =
      'ca-app-pub-1474045642143501/2559155589';

  /// Size of the banner ad.
  static const AdSize size = AdSize.banner;

  /// Whether banner ads are supported on the current platform.
  ///
  /// Google Mobile Ads does not support loading mobile ads on Web.
  static bool get enabled {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Returns the AdMob banner unit ID.
  ///
  /// The same real AdMob unit is used in Debug, Profile, and Release builds.
  static String get adUnitId => bannerAdUnitId;

  BannerAd? _ad;
  bool _disposed = false;

  /// Loads the banner ad.
  ///
  /// [onLoaded] is called when the ad has been successfully loaded.
  /// [onFailed] is called when the ad cannot be loaded.
  void load({
    required void Function(BannerAd ad) onLoaded,
    VoidCallback? onFailed,
  }) {
    if (!enabled) {
      onFailed?.call();
      return;
    }

    // Prevent duplicate ad requests.
    if (_ad != null) return;

    late final BannerAd banner;

    banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (_disposed) {
            banner.dispose();
            return;
          }

          AppLog.d(
            'Ads',
            'banner loaded (${size.width}x${size.height})',
          );

          onLoaded(banner);
        },
        onAdFailedToLoad: (ad, error) {
          AppLog.e(
            'Ads',
            'banner failed: ${error.code} ${error.message}',
          );

          ad.dispose();
          _ad = null;

          if (!_disposed) {
            onFailed?.call();
          }
        },
      ),
    );

    _ad = banner;
    banner.load();
  }

  /// Releases the banner ad resources.
  void dispose() {
    _disposed = true;
    _ad?.dispose();
    _ad = null;
  }
}

/// Banner ad widget used on the settings screen.
///
/// The widget remains hidden until the banner is successfully loaded.
/// If the ad cannot be loaded, no empty placeholder is displayed.
class SettingsBannerAd extends StatefulWidget {
  const SettingsBannerAd({super.key});

  @override
  State<SettingsBannerAd> createState() => _SettingsBannerAdState();
}

class _SettingsBannerAdState extends State<SettingsBannerAd> {
  final BannerAdSlot _slot = BannerAdSlot();

  BannerAd? _ad;

  @override
  void initState() {
    super.initState();

    if (!BannerAdSlot.enabled) {
      return;
    }

    _slot.load(
      onLoaded: (ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }

        setState(() {
          _ad = ad;
        });
      },
      onFailed: () {
        // No-fill or network errors are intentionally hidden from the user.
        if (!mounted) return;

        setState(() {
          _ad = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _slot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;

    if (ad == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            AppRadius.md,
          ),
          child: SizedBox(
            width: BannerAdSlot.size.width.toDouble(),
            height: BannerAdSlot.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        ),
      ),
    );
  }
}