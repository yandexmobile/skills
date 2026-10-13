#!/usr/bin/env bash
# Mechanical renames from steps/03_mechanical_renames.md.
# Context-sensitive renames (.adUnitId, .info, Rating) are manual: see steps/03.
set -euo pipefail
PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

tmp="$(mktemp)"
find . -name "*.swift" -not -path "*/Pods/*" -not -path "*/.build/*" -not -path "*/DerivedData/*" -print0 >"$tmp"
trap 'rm -f "$tmp"' EXIT

run_perl() {
  xargs -0 perl -pi -e "$1" <"$tmp"
}

# 3.1 MobileAds → YandexAds (Yandex SDK only: skip OtherModule.MobileAds.* e.g. GoogleMobileAds.MobileAds)
run_perl 's/(?<!\.)\b(YandexMobileAds\.)?MobileAds\.initialize\(\)/$1YandexAds.initializeSDK(completionHandler: nil)/g'
run_perl 's/(?<!\.)\b(YandexMobileAds\.)?MobileAds\.sdkVersion\b/$1YandexAds.sdkVersion.stringValue/g'
run_perl 's/(?<!\.)\b(YandexMobileAds\.)?MobileAds\.setLocationTrackingEnabled\(/$1YandexAds.setLocationTracking(/g'
run_perl 's/(?<!\.)\b(YandexMobileAds\.)?MobileAds\.setAgeRestrictedUser\(/$1YandexAds.setAgeRestricted(/g'
run_perl 's/(?<!\.)\b(YandexMobileAds\.)?MobileAds\.setUserConsent\(/$1YandexAds.setUserConsent(/g'
run_perl 's/(?<!\.)\b(YandexMobileAds\.)?MobileAds\.audioSessionManager\(\)/$1YandexAds.audioSessionManager/g'
run_perl 's/(?<!\.)\b(YandexMobileAds\.)?MobileAds\./$1YandexAds./g unless /import YandexMobileAds/'
run_perl 's/(?<!await )YandexAds\.initializeSDK\(\s*\)/YandexAds.initializeSDK(completionHandler: nil)/g'
run_perl 's/\bYMANativeAdView\b/NativeAdView/g'
run_perl 's/\bYMANativeMediaView\b/NativeMediaView/g'

# 3.2 Targeting
run_perl 's/\bAdTargetInfo\b/AdTargeting/g'
run_perl 's/\.targetInfo\b/.targeting/g'
run_perl 's/\bkYMAGenderFemale\b/Gender.female/g'
run_perl 's/\bkYMAGenderMale\b/Gender.male/g'

# 3.3 BannerAdSize
run_perl 's/BannerAdSize\.fixedSize\(withWidth:/BannerAdSize.fixed(width:/g'
run_perl 's/BannerAdSize\.inlineSize\(withWidth:/BannerAdSize.inline(width:/g'
run_perl 's/BannerAdSize\.stickySize\(withContainerWidth:/BannerAdSize.sticky(containerWidth:/g'

# 3.4 BidderTokenRequest
run_perl 's/\bBidderTokenRequestConfiguration\b/BidderTokenRequest/g'
run_perl 's/loadBidderToken\(requestConfiguration:/loadBidderToken(request:/g'

# 3.5 BidderTokenLoader
run_perl 's/BidderTokenLoader\(mediationNetworkName:[^)]*\)/BidderTokenLoader()/g'

# 3.6 AdInfo / properties
run_perl 's/\bAdInfo\.data\b/AdInfo.extraData/g'
run_perl 's/\bAdRequestError\.adUnitId\b/AdRequestError.adUnitID/g'
run_perl 's/\.adAttributes\b/.adInfo?.creatives/g'

# 3.7 Delegates
run_perl 's/didFailToShowWithError/didFailToShow/g'
run_perl 's/didTrackImpressionWith\b/didTrackImpression/g'

# 3.9 AdRequest class names (longest first)
run_perl 's/\bMutableNativeAdRequestConfiguration\b/AdRequest/g'
run_perl 's/\bMutableAdRequestConfiguration\b/AdRequest/g'
run_perl 's/\bNativeAdRequestConfiguration\b/AdRequest/g'
run_perl 's/\bAdRequestConfiguration\b/AdRequest/g'
run_perl 's/\bMutableAdRequest\b/AdRequest/g'

# 3.10 AdMob extra assets
while IFS= read -r -d '' f; do
  [[ -f "$f" ]] || continue
  perl -pi -e '
    s/kYMAAdMobNativeAdAgeExtraAsset/YandexAdMobNativeAdExtraAssets.age/g;
    s/kYMAAdMobNativeAdFaviconExtraAsset/YandexAdMobNativeAdExtraAssets.favicon/g;
    s/kYMAAdMobNativeAdReviewCountExtraAsset/YandexAdMobNativeAdExtraAssets.reviewCount/g;
    s/kYMAAdMobNativeAdWarningExtraAsset/YandexAdMobNativeAdExtraAssets.warning/g;
  ' "$f"
done <"$tmp"

# 3.11 Manual: show deleted constants and types
echo "=== Manual review (3.11): remove or replace deleted constants and types ==="
echo "--- Deleted error domain constants:"
xargs -0 grep -sn "kYMAAdsErrorDomain\|kYMANativeAdErrorDomain" <"$tmp" 2>/dev/null || true
echo "--- Deleted Version properties:"
xargs -0 grep -sn "\.prereleaseIdentifiers\|\.buildMetadataIdentifiers" <"$tmp" 2>/dev/null || true
echo "--- Deleted AdInfo.adSize:"
xargs -0 grep -sn "\.adInfo\.adSize\b" <"$tmp" 2>/dev/null || true

echo "Mechanical pass done. Apply the manual renames from steps/03 (.adUnitId, .info, Rating), then run verify_mechanical_renames.sh."
