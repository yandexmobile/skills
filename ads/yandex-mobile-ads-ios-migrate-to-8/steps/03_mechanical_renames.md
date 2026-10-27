# Step 3: Mechanical Renames

> **First, read [`../general_rules.md`](../general_rules.md).**

Run the script to apply all mechanical renames at once:

```bash
bash "$MIGRATION_PACK/scripts/apply_mechanical_renames.sh" /path/to/MyApp
```

Then apply the **manual renames** marked below (`.adUnitId`, `.info`, `Rating`) and Step 3.11.

> **IMPORTANT**: The `import YandexMobileAds` statement must NOT be modified. The script is crafted to avoid this.

## What the Script Does

The sections below describe each rename for reference. All are executed by `apply_mechanical_renames.sh`, except the context-sensitive ones marked **manual**: a project-wide regex would also rename the app's own properties, so rename them only on Yandex SDK objects. Compile errors after the SDK update point to the remaining places.

### 3.1 Rename `MobileAds` Class → `YandexAds`

| SDK 7                                      | SDK 8                                              |
|--------------------------------------------|---------------------------------------------------|
| `MobileAds.initialize()`                   | `YandexAds.initializeSDK(completionHandler: nil)` |
| `MobileAds.sdkVersion`                     | `YandexAds.sdkVersion.stringValue`                |
| `MobileAds.setLocationTrackingEnabled(…)`  | `YandexAds.setLocationTracking(…)`    |
| `MobileAds.setAgeRestrictedUser(…)`        | `YandexAds.setAgeRestricted(…)`       |
| `MobileAds.setUserConsent(…)`              | `YandexAds.setUserConsent(…)`         |
| `MobileAds.audioSessionManager()`          | `YandexAds.audioSessionManager`       |
| `MobileAds.*` (remaining, **unqualified**) | `YandexAds.*` (see rules below)       |
| `YMANativeAdView`                          | `NativeAdView`                        |
| `YMANativeMediaView`                       | `NativeMediaView`                     |

**Qualified `MobileAds` must stay untouched.** The script only replaces `MobileAds.` when it is **not** immediately preceded by `.` (Perl: `(?<!\.) \bMobileAds.`). That way names like `GoogleMobileAds.MobileAds.shared`, `Facebook…` or any `OtherModule.MobileAds.*` are **not** rewritten to `YandexAds`.

**Lines containing** `import YandexMobileAds` are skipped for the bulk `MobileAds.*` replacement so the import line is never corrupted.

The script uses `YandexAds.initializeSDK(completionHandler: nil)` as a
mechanical replacement, including for a stray non-`await`
`YandexAds.initializeSDK()`. After it runs, apply the API choice recorded
during discovery: keep the completion form (with a handler if needed), or
use `await YandexAds.initializeSDK()` in the selected async startup flow.
The script's output does not override project rules or the user's choice.
Preserve privacy settings before initialization and the first ad request.

### 3.2 Rename Targeting

| SDK 7              | SDK 8           |
|--------------------|-----------------|
| `AdTargetInfo`     | `AdTargeting`   |
| `.targetInfo`      | `.targeting`    |
| `kYMAGenderFemale` | `Gender.female` |
| `kYMAGenderMale`   | `Gender.male`   |

### 3.3 Rename `BannerAdSize` Factory Methods

| SDK 7                                           | SDK 8                                   |
|-------------------------------------------------|-----------------------------------------|
| `BannerAdSize.fixedSize(withWidth:…)`           | `BannerAdSize.fixed(width:…)`           |
| `BannerAdSize.inlineSize(withWidth:…)`          | `BannerAdSize.inline(width:…)`          |
| `BannerAdSize.stickySize(withContainerWidth:…)` | `BannerAdSize.sticky(containerWidth:…)` |

### 3.4 Rename `BidderTokenRequestConfiguration` → `BidderTokenRequest`

| SDK 7                                     | SDK 8                        |
|-------------------------------------------|------------------------------|
| `BidderTokenRequestConfiguration`         | `BidderTokenRequest`         |
| `loadBidderToken(requestConfiguration:…)` | `loadBidderToken(request:…)` |

> **Note**: After the rename, `BidderTokenRequest` uses factory methods instead of the old initializer. The old `BidderTokenRequestConfiguration(adType:)` + mutable properties pattern must be replaced with factory methods. This requires AI review — see Step 5 for details on `BidderTokenRequest.banner(size:targeting:parameters:)`, `.interstitial()`, `.rewarded()`, `.native()`, `.appOpenAd()`.

### 3.5 Remove `mediationNetworkName` from `BidderTokenLoader`

`BidderTokenLoader(mediationNetworkName:…)` → `BidderTokenLoader()`

> **Note**: Adapter identification is now set globally via `AdapterIdentity` before SDK initialization. See Step 5 for the `AdapterIdentity` + `YandexAds.setAdapterIdentity()` + `YandexAds.initializeSDK(completionHandler: nil)` pattern.

### 3.6 Rename `AdInfo` and Ad Object Properties

| SDK 7                     | SDK 8                                                 |
|---------------------------|-------------------------------------------------------|
| `.adUnitId` (**manual**)  | `.adUnitID`                                           |
| `AdInfo.data`             | `AdInfo.extraData`                                    |
| `AdRequestError.adUnitId` | `AdRequestError.adUnitID`                             |
| `.adAttributes`           | `.adInfo?.creatives`                                  |
| `.info` (**manual**)      | `.adInfo?.extraData`                                  |

> **Manual**: rename `.adUnitId` and `.info` only on Yandex SDK objects (for example `nativeAd.info`, `interstitialAd.adUnitId`), never on the app's own types such as `user.info` or `self.adUnitId`.

### 3.7 Rename Delegate Methods

| SDK 7                    | SDK 8                 |
|--------------------------|-----------------------|
| `didFailToShowWithError` | `didFailToShow`       |
| `didTrackImpressionWith` | `didTrackImpression`  |

### 3.8 Rename `Rating` API (**manual**)

Migrate calls on `Rating` instances, for example `rating.setRating(value)` → `rating.rating = value`. Protocol implementations are covered in Step 8.

| SDK 7                     | SDK 8                   |
|---------------------------|-------------------------|
| `Rating.setRating(value)` | `Rating.rating = value` |
| `Rating.rating()`         | `Rating.rating`         |

### 3.9 Rename `AdRequest` Classes

All old request configuration classes → `AdRequest` (longest names first to avoid partial matches):

- `MutableNativeAdRequestConfiguration` → `AdRequest`
- `MutableAdRequestConfiguration` → `AdRequest`
- `NativeAdRequestConfiguration` → `AdRequest`
- `AdRequestConfiguration` → `AdRequest`
- `MutableAdRequest` → `AdRequest`

### 3.10 Rename AdMob Extra Asset Constants

| SDK 7                                       | SDK 8                                        |
|---------------------------------------------|----------------------------------------------|
| `kYMAAdMobNativeAdAgeExtraAsset`            | `YandexAdMobNativeAdExtraAssets.age`         |
| `kYMAAdMobNativeAdFaviconExtraAsset`        | `YandexAdMobNativeAdExtraAssets.favicon`     |
| `kYMAAdMobNativeAdReviewCountExtraAsset`    | `YandexAdMobNativeAdExtraAssets.reviewCount` |
| `kYMAAdMobNativeAdWarningExtraAsset`        | `YandexAdMobNativeAdExtraAssets.warning`     |

### 3.11 Remove Deleted Constants and Types (manual)

The script prints occurrences but does not auto-remove. Search and manually remove lines containing these deleted constants and types (no direct replacement exists):

**Deleted error domain constants**:
- `kYMAAdsErrorDomain`
- `kYMANativeAdErrorDomain`

`AdErrorCode`, `NativeErrorCode`, `isYandexMobileAdsError` and `isYandexMobileNativeAdsError` were removed in 8.0.0 and returned in 8.4.0. The target is the latest 8.x, so keep them.

**Deleted Version properties**:
- `Version.prereleaseIdentifiers`
- `Version.buildMetadataIdentifiers`

## Verification

Run the verification script:

```bash
bash "$MIGRATION_PACK/scripts/verify_mechanical_renames.sh" .
```

- [ ] Script exits with code 0
- [ ] `import YandexMobileAds` statements are preserved
- [ ] Changes made by script do exactly what described in this step
- [ ] Manual renames (`.adUnitId`, `.info`, `Rating`) applied only to Yandex SDK objects
