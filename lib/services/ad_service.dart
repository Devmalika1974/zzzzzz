// Empty ad service class that provides stubs for all methods that were previously used
// This allows the app to function without AdMob integration

class AdService {
  // Initialize method (does nothing now)
  Future<void> initialize() async {
    // No initialization needed without AdMob
  }

  // Stub methods that return false or empty futures
  Future<bool> loadAppOpenAd() async {
    return false;
  }

  void showAppOpenAd() {
    // No implementation needed
  }

  Future<dynamic> loadNativeAd({String factoryId = 'listTile'}) async {
    return null;
  }

  Future<bool> loadInterstitialAd() async {
    return false;
  }

  void showInterstitialAd() {
    // No implementation needed
  }

  Future<bool> loadRewardedAd() async {
    return false;
  }

  void showRewardedAd({
    required void Function(dynamic, dynamic) onUserEarnedReward,
    dynamic onAdShowed,
    dynamic onAdDismissed,
    Function(dynamic)? onAdFailedToShow,
  }) {
    // Simulate user earning reward immediately
    // Pass dummy values to the callback
    onUserEarnedReward(null, null);
  }

  void dispose() {
    // No resources to dispose
  }
}