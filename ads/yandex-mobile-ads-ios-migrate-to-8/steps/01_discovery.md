# Step 1: Discover Files to Migrate

> **First, read [`../general_rules.md`](../general_rules.md).**

Before making any changes, scan the entire project to build a complete list of files that need migration. Do NOT start editing until discovery is complete.

## 1.1 Find Dependency Files

Search for:
- `Podfile` — look for `pod 'YandexMobileAds'` lines
- `Package.swift` or Xcode SPM references — look for `YandexMobileAds` package dependency
- `*.podspec` files — look for dependencies on `YandexMobileAds`

## 1.2 Find All Files Using the SDK

If the project is multi-target, search all targets. Search for **all** `.swift` (or `.m`, `.h`) files containing any of these markers:

```
import YandexMobileAds
@import YandexMobileAds
#import <YandexMobileAds/YandexMobileAds.h>
MobileAds
AdRequestConfiguration
NativeAdRequestConfiguration
MutableAdRequest
MutableAdRequestConfiguration
MutableNativeAdRequestConfiguration
AdView
AdViewDelegate
BidderTokenRequestConfiguration
BidderTokenLoader
AdTargetInfo
NativeAdImageLoadingObserver
NativeTemplateAppearance
NativeBannerView
VideoController
VideoDelegate
kYMAAdsErrorDomain
kYMANativeAdErrorDomain
kYMAGenderFemale
kYMAGenderMale
AppOpenAdLoaderDelegate
InterstitialAdLoaderDelegate
RewardedAdLoaderDelegate
NativeAdLoaderDelegate
NativeBulkAdLoaderDelegate
SliderAdLoaderDelegate
InstreamAdLoaderDelegate
YMANativeAdView
YMANativeMediaView
audioSessionManager
sdkVersion
AdInfo
AdRequestError
Rating.setRating
Rating.rating()
NativeVideoPlaybackProgressControl
.adAttributes
.creativeID
.campaignID
.info
.adSize
loadImages
mediationNetworkName
AdRequestTokenConfiguration
NativeAdOptions
NativeAdWarning
AdapterIdentity
fixedSize(withWidth
inlineSize(withWidth
stickySize(withContainerWidth
didFailToShowWithError
didTrackImpressionWith
bind(toSliderView
prereleaseIdentifiers
buildMetadataIdentifiers
```

## 1.3 Select the iOS API Style

Apply [General Rules, section 9](../general_rules.md#9-choosing-between-completion-handler-and-asyncawait)
before rewriting code. Read applicable project instructions and inspect
the discovered integration's neighboring async/completion patterns. Record
the selected approach and its reason for each affected integration/module.
If the evidence is inconclusive, ask the user before moving to API changes.
Keep this decision in the migration progress, without adding a log file.

## 1.4 Report Findings

Inform the user about:
- Total number of files that need changes
- Which files are affected and by which steps
- Any Objective-C files detected (warn that the guide covers Swift only)

## Verification

- [ ] All dependency files (`Podfile`, `Package.swift`, `*.podspec`) have been identified
- [ ] All `.swift` files containing SDK markers have been listed
- [ ] The user has been informed about the scope of changes
- [ ] If Objective-C files are present, the user has been warned
