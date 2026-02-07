import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

class AdService {
  BannerAd createInlineBanner(BuildContext context, String adUnitId) {
    final screenWidth = MediaQuery.of(context).size.width.round();
    const bannerMaxHeight = 150;

    late BannerAd banner;
    banner = BannerAd(
      adUnitId: adUnitId,
      adSize: BannerAdSize.inline(width: screenWidth, maxHeight: bannerMaxHeight),
      adRequest: const AdRequest(),
      onAdLoaded: () {
        // The ad was loaded successfully. Now it will be shown.
        if (kDebugMode) {
          print('Inline banner loaded successfully.');
        }
        if (!context.mounted) {
          banner.destroy();
          return;
        }
      },
      onAdFailedToLoad: (error) {
        // Ad failed to load with AdRequestError.
        if (kDebugMode) {
          print('Failed to load inline banner: ${error.description}');
        }
      },
      onAdClicked: () {
        // Called when a click is recorded for an ad.
      },
      onLeftApplication: () {
        // Called when user is about to leave application
      },
      onReturnedToApplication: () {
        // Called when user returned to application after click.
      },
      onImpression: (impressionData) {
        // Called when an impression is recorded for an ad.
      },
    );
    return banner;
  }

  BannerAd createStickyBanner(BuildContext context, String adUnitId) {
    final screenWidth = MediaQuery.of(context).size.width.round();
    final adSize = BannerAdSize.sticky(width: screenWidth);

    late BannerAd banner;
    banner = BannerAd(
      adUnitId: adUnitId,
      adSize: adSize,
      adRequest: const AdRequest(),
      onAdLoaded: () {
        if (kDebugMode) {
          print('Sticky banner loaded successfully.');
        }
        if (!context.mounted) {
          banner.destroy();
          return;
        }
      },
      onAdFailedToLoad: (error) {
        if (kDebugMode) {
          print('Failed to load sticky banner: ${error.description}');
        }
      },
      onAdClicked: () {
        // Called when a click is recorded for an ad.
      },
      onLeftApplication: () {
        // Called when user is about to leave application
      },
      onReturnedToApplication: () {
        // Called when user returned to application after click.
      },
      onImpression: (impressionData) {
        // Called when an impression is recorded for an ad.
      },
    );
    return banner;
  }
}