import 'dart:io';

import 'package:flipcard/helpers/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdType { interstitial, appOpen, banner, rewarded }

class AdMob {
  AdMob._();

  static final int _maxAttemps = 3;
  static final Map<AdType, dynamic> _ads = {};
  static final Map<AdType, bool> _ready = {};
  static final Map<AdType, DateTime?> _times = {};
  static final Map<AdType, int> _retryAttempts = {};

  static const Map<AdType, Map<String, String>> _ids = {
    AdType.interstitial: {
      'android': 'ca-app-pub-3411797729179357/5735268678',
      'ios': 'ca-app-pub-3411797729179357/5871764385',
    },
    AdType.appOpen: {
      'android': 'ca-app-pub-3411797729179357/2725961955',
      'ios': 'ca-app-pub-3411797729179357/5599870447',
    },
    AdType.banner: {
      'android': 'ca-app-pub-3411797729179357/YOUR_BANNER_ANDROID_ID',
      'ios': 'ca-app-pub-3411797729179357/YOUR_BANNER_IOS_ID',
    },
    AdType.rewarded: {
      'android': 'ca-app-pub-3411797729179357/2171761328',
      'ios': 'ca-app-pub-3411797729179357/8226033788',
    },
  };

  static dynamic getAd(AdType adType) => _ads[adType];
  static String unitId(AdType adType) => _unitId(adType);
  static bool isReady(AdType adType) => _ready[adType] ?? false;

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      for (AdType type in AdType.values) {
        _ready[type] = false;
        _retryAttempts[type] = 0;
        load(type);
      }
      _log('initialization success');
    } catch (e) {
      _log('initialization failed: $e');
    }
  }

  static void dispose([AdType? adType]) {
    if (adType != null) {
      return _dispose(adType);
    }

    // Dispose all ads
    for (AdType type in AdType.values) {
      _dispose(type);
    }

    _ads.clear();
    _ready.clear();
    _retryAttempts.clear();
  }

  static Future<void> show(
    AdType type, {
    Function(AdWithoutView, RewardItem)? onEarned,
  }) async {
    try {
      if (!(_ready[type] ?? false) || _ads[type] == null) {
        _log('Warning: Attempt to show ${type.name} before loaded');
        load(type);
        return;
      }

      // check expiration for app open ads
      if (type == AdType.appOpen && _isExpired(type)) {
        _log('${type.name} ad expired, loading new one');
        _dispose(type);
        load(type);
        return;
      }

      final ad = _ads[type];
      switch (type) {
        case AdType.interstitial:
          await (ad as InterstitialAd).show();
          break;
        case AdType.appOpen:
          await (ad as AppOpenAd).show();
          break;
        case AdType.banner:
          // Banner ads are handled differently - return the widget
          _log('Use getBannerWidget() for banner ads');
          break;
        case AdType.rewarded:
          await (ad as RewardedAd).show(
            onUserEarnedReward: onEarned ?? (x, y) => _log('${y.amount}'),
          );
          break;
      }
    } catch (e) {
      _log(e.toString());
    }
  }

  static void load(AdType type) {
    final unitId = _unitId(type);
    final request = AdRequest(
      nonPersonalizedAds: false,
      keywords: [
        'tech',
        'money',
        'investment',
        'education',
        'learning',
        'language',
        'travel',
        'explore',
      ],
    );

    switch (type) {
      case AdType.interstitial:
        InterstitialAd.load(
          request: request,
          adUnitId: unitId,
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) => _onLoad(type, ad),
            onAdFailedToLoad: (LoadAdError error) =>
                _onLoadFailed(AdType.interstitial, error),
          ),
        );
        break;
      case AdType.appOpen:
        AppOpenAd.load(
          request: request,
          adUnitId: unitId,
          adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (AppOpenAd ad) => _onLoad(type, ad),
            onAdFailedToLoad: (LoadAdError error) =>
                _onLoadFailed(AdType.appOpen, error),
          ),
        );
        break;
      case AdType.banner:
        // BannerAd(
        //   adUnitId: unitId,
        //   request: request,
        //   size: AdSize.banner,
        //   listener: BannerAdListener(
        //     onAdLoaded: (Ad ad) => _onLoad(type, ad),
        //     onAdFailedToLoad: (Ad ad, LoadAdError error) {
        //       ad.dispose();
        //       _onLoadFailed(AdType.banner, error);
        //     },
        //   ),
        // ).load();
        break;
      case AdType.rewarded:
        RewardedAd.load(
          request: request,
          adUnitId: unitId,
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (RewardedAd ad) => _onLoad(type, ad),
            onAdFailedToLoad: (LoadAdError error) =>
                _onLoadFailed(AdType.rewarded, error),
          ),
        );
        break;
    }
  }

  static void reload(AdType type) {
    _log('Reloading ${type.name} ad...');
    _dispose(type);
    _retryAttempts[type] = 0;
    load(type);
  }

  static void reloadAll() {
    _log('Reloading all ads...');
    for (AdType type in AdType.values) {
      _dispose(type);
      _retryAttempts[type] = 0;
      load(type);
    }
  }

  static Widget? getBannerWidget() {
    if (_ready[AdType.banner] == true && _ads[AdType.banner] != null) {
      return Container(
        alignment: Alignment.center,
        width: (_ads[AdType.banner] as BannerAd).size.width.toDouble(),
        height: (_ads[AdType.banner] as BannerAd).size.height.toDouble(),
        child: AdWidget(ad: _ads[AdType.banner] as BannerAd),
      );
    }
    return null;
  }

  static void _onLoad(AdType type, dynamic ad) {
    _log('${type.name} ad loaded successfully');
    _ads[type] = ad;
    _ready[type] = true;
    _retryAttempts[type] = 0;
    _times[type] = DateTime.now();

    final callback = FullScreenContentCallback<AdWithoutView>(
      onAdShowedFullScreenContent: (ad) {
        _log('${type.name} ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _dispose(type);
        _log('${type.name} ad dismissed by user');
        Future.delayed(Duration(seconds: 2), () => load(type));
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _dispose(type);
        _log('${type.name} ad failed to show: $error');
        Future.delayed(Duration(seconds: 2), () => load(type));
      },
      onAdImpression: (ad) {
        _log('${type.name} ad impression recorded');
      },
    );

    if (ad is InterstitialAd) {
      ad.fullScreenContentCallback =
          callback as FullScreenContentCallback<InterstitialAd>;
    } else if (ad is AppOpenAd) {
      ad.fullScreenContentCallback =
          callback as FullScreenContentCallback<AppOpenAd>;
    } else if (ad is RewardedAd) {
      ad.fullScreenContentCallback =
          callback as FullScreenContentCallback<RewardedAd>;
    }
  }

  static void _onLoadFailed(AdType adType, LoadAdError error) {
    _log('${adType.name} ad failed to load: $error');
    _ready[adType] = false;
    _retry(adType, error);
  }

  static void _retry(AdType adType, LoadAdError error) {
    _log(
      '${adType.name} error details: Code=${error.code}, Domain=${error.domain}, Message=${error.message}',
    );

    final attempts = _retryAttempts[adType] ?? 0;
    if (attempts < _maxAttemps) {
      _retryAttempts[adType] = attempts + 1;
      final delaySeconds = (attempts + 1) * 10;
      _log('Retrying ${adType.name} in ${delaySeconds}s...');

      Future.delayed(Duration(seconds: delaySeconds), () {
        if (!(_ready[adType] ?? false)) {
          load(adType);
        }
      });
    } else {
      _log('Max ${adType.name} retry attempts reached. Stopping.');
      _retryAttempts[adType] = 0;
    }
  }

  static String _unitId(AdType adType) {
    final platform = Platform.isAndroid ? 'android' : 'ios';
    return _ids[adType]?[platform] ?? '';
  }

  static bool _isExpired(AdType type) {
    final time = _times[type];
    if (time == null) return true;

    // App open ads expire after 4 hours
    final hour = type == AdType.appOpen ? 4 : 1;

    return DateTime.now().difference(time).inHours >= hour;
  }

  static void _dispose(AdType type) {
    _ads[type]?.dispose();
    _ads[type] = null;
    _ready[type] = false;
    _times[type] = null;
  }

  static void _log(String message) {
    Logger.log(message, name: "AdMob");
  }
}
