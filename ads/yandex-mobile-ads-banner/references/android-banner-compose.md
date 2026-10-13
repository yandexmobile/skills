# AI Integration Agent Instructions for Android Banner Ads with Jetpack Compose

## Required Imports

Add `mobileads-compose` next to `mobileads` with the same version (its POM
does not pull `mobileads`, keep both), and
`androidx.lifecycle:lifecycle-runtime-compose` 2.7.0 or newer. The app must
use Jetpack Compose BOM 2024.01.00 or newer:

```kotlin
implementation("com.yandex.android:mobileads:<latest>")
implementation("com.yandex.android:mobileads-compose:<latest>")
```

```kotlin
import android.util.Log
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.LifecycleStartEffect
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.compose.Banner
import com.yandex.mobile.ads.compose.BannerEvents
import com.yandex.mobile.ads.compose.BannerSize
import com.yandex.mobile.ads.compose.rememberBannerAdState
```

## Method Signatures

```kotlin
@Composable
fun rememberBannerAdState(adSize: BannerSize, events: BannerEvents = BannerEvents()): BannerAdState

@Composable
fun Banner(state: BannerAdState, modifier: Modifier = Modifier)

BannerAdState.loadAd(adRequest: AdRequest)
BannerSize.Sticky(width: Dp)
BannerSize.Inline(width: Dp, maxHeight: Dp)
BannerEvents(onAdLoaded, onAdFailedToLoad, onAdClicked, onImpression)
```

## Gotchas

- **Main thread:** the SDK API and all its callbacks are `@MainThread`.
- **Version.** Requires `mobileads-compose` 8.5.0 or newer (the state owns the
  ad view); if older, update both artifacts first.
- **The state owns the ad.** It destroys the view when it leaves the
  composition. In a `LazyColumn` create the state above the list, one state
  per placement; sharing a state shows one ad in several places.
- **Changing `adSize` recreates the state**, so a new width after rotation
  loads a new ad; key the load flags by the width, as below.
- **Failed load.** Only log it. The next time the screen starts, the banner
  loads again if it never loaded; a loaded banner refreshes itself.
- **Mediation.** With mediation adapters, create the sticky banner state after
  `YandexAds.initialize` has completed; before that the size is preliminary.
- **Edge-to-edge.** For a bottom banner apply `navigationBarsPadding()`.
- **Video in inline banners** needs hardware acceleration. If the app disables
  it, enable it for the activities that show ads.

## Banner workflow

Names such as `TAG` or `BANNER_AD_UNIT_ID` are placeholders; use the app's own
names and declare constants at the top of the file.

1. **Choose the placement and the banner type**
   - [ ] Sticky (default) at a screen edge, inline inside an article:
     `BannerSize.Inline(width = maxWidth, maxHeight = 250.dp)`.

2. **Create the ad view with the size computed from the container width**
   - [ ] Take the width from `BoxWithConstraints`, never hard-code it. Add
     this composable and place it where the banner goes:

     ```kotlin
     @Composable
     fun StickyBanner(modifier: Modifier = Modifier) {
         BoxWithConstraints(modifier.fillMaxWidth()) {
             var isLoading by remember(maxWidth) { mutableStateOf(false) }
             var hasLoaded by remember(maxWidth) { mutableStateOf(false) }
             val bannerState = rememberBannerAdState(
                 adSize = BannerSize.Sticky(width = maxWidth),
                 events = BannerEvents(
                     onAdLoaded = {
                         isLoading = false
                         hasLoaded = true
                     },
                     onAdFailedToLoad = { error ->
                         isLoading = false
                         Log.w(TAG, error.description)
                     },
                 ),
             )
             LifecycleStartEffect(bannerState) {
                 if (!hasLoaded && !isLoading) {
                     isLoading = true
                     bannerState.loadAd(AdRequest.Builder(BANNER_AD_UNIT_ID).build())
                 }
                 onStopOrDispose { }
             }
             Banner(state = bannerState, modifier = Modifier.fillMaxWidth())
         }
     }
     ```

3. **Register for ad events**
   - [ ] Pass callbacks through `BannerEvents` as above.

4. **Load the ad**
   - [ ] `LifecycleStartEffect` loads when the screen starts, and again on the
     next start if the banner never loaded.

5. **Release the ad view with its screen**
   - [ ] Nothing to call: the state destroys the view when it leaves the
     composition.

## Verify the build

- [ ] Run `./gradlew assembleDebug` (fallback `gradle assembleDebug`). Fix any
  Yandex SDK related compile errors.

### Links

Additional documentation:

- https://ads.yandex.com/helpcenter/en/dev/android/compose/adaptive-sticky-banner.md
- https://ads.yandex.com/helpcenter/en/dev/android/compose/adaptive-inline-banner.md
