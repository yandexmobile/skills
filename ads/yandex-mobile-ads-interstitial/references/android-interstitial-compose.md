# AI Integration Agent Instructions for Android Interstitial Ads with Jetpack Compose

## Required Imports

Add `mobileads-compose` next to `mobileads` with the same version (its POM
does not pull `mobileads`, keep both). The app must use Jetpack Compose BOM
2024.01.00 or newer:

```kotlin
implementation("com.yandex.android:mobileads:<latest>")
implementation("com.yandex.android:mobileads-compose:<latest>")
```

```kotlin
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.os.SystemClock
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import com.yandex.mobile.ads.common.AdError
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.common.ImpressionData
import com.yandex.mobile.ads.compose.rememberInterstitialAdLoader
import com.yandex.mobile.ads.interstitial.InterstitialAd
import com.yandex.mobile.ads.interstitial.InterstitialAdEventListener
import com.yandex.mobile.ads.interstitial.InterstitialAdLoadResult
```

## Method Signatures

```kotlin
@Composable
fun rememberInterstitialAdLoader(): InterstitialAdLoaderState

InterstitialAdLoaderState.loadAd(adRequest: AdRequest): InterstitialAdLoadResult  // suspend
InterstitialAdLoadResult.Success(ad: InterstitialAd) / Failure(error: AdRequestError)
InterstitialAd.show(activity: Activity)
```

## Gotchas

- **Main thread:** the SDK API and all its callbacks are `@MainThread`.
- **Loader lifetime.** `rememberInterstitialAdLoader()` cancels loading when it
  leaves the composition: call it on the screen that leads to the transition.
- **Nothing is shown automatically.** `show` needs an `Activity`.
- **Failed load.** Only log it; the next transition point loads again.
- **Screen recreated under the ad.** The ad runs in a separate activity, so the
  screen can be recreated while it is on screen (rotation, a creative that
  changes orientation, "Don't keep activities"). The old listener would still
  fire; it is cleared in `onDispose`, so the transition is lost. If that
  matters, keep the show logic in a `ViewModel` or an app-level object.

## Interstitial workflow

Names such as `TAG`, `onLevelComplete` or `INTERSTITIAL_AD_UNIT_ID` are
placeholders; use the app's own names and declare constants at the top of the
file.

1. **Choose the transition point where the ad is shown**
   - [ ] Declare these objects once per app, in the app's `ads` package, one file per
     object; skip any that already exists.
     `MIN_INTERVAL_MS` is the value from the user. `findActivity()` goes to a
     shared util file in the `ads` package:

     ```kotlin
     object FullscreenAdState {
         var isFullscreenAdShowing = false
     }

     object InterstitialFrequency {
         const val MIN_INTERVAL_MS = 60_000L
         var lastShownAtMs = -MIN_INTERVAL_MS
     }

     tailrec fun Context.findActivity(): Activity = when (this) {
         is Activity -> this
         is ContextWrapper -> baseContext.findActivity()
         else -> error("No Activity in the context chain")
     }
     ```

2. **Create one ad loader and load the ad in advance**
   - [ ] On the screen with the transition point, add this state holder and
     call `val completeLevel = rememberInterstitialTransition(onLevelComplete)`;
     call `completeLevel()` at the transition:

     ```kotlin
     @Composable
     fun rememberInterstitialTransition(onContinue: () -> Unit): () -> Unit {
         val activity = LocalContext.current.findActivity()
         val loader = rememberInterstitialAdLoader()
         var interstitialAd by remember { mutableStateOf<InterstitialAd?>(null) }
         var isLoading by remember { mutableStateOf(false) }
         var shownAd by remember { mutableStateOf<InterstitialAd?>(null) }
         var loadKey by remember { mutableIntStateOf(0) }

         LaunchedEffect(loadKey) {
             isLoading = true
             when (val result = loader.loadAd(AdRequest.Builder(INTERSTITIAL_AD_UNIT_ID).build())) {
                 is InterstitialAdLoadResult.Success -> interstitialAd = result.ad
                 is InterstitialAdLoadResult.Failure -> Log.w(TAG, result.error.description)
             }
             isLoading = false
         }
         DisposableEffect(Unit) {
             onDispose {
                 if (shownAd != null) FullscreenAdState.isFullscreenAdShowing = false
                 shownAd?.setAdEventListener(null)
             }
         }

         fun onFinished() {
             shownAd = null
             FullscreenAdState.isFullscreenAdShowing = false
             loadKey++
             onContinue()
         }

         return showOrContinue@{
             if (shownAd != null) return@showOrContinue
             val ad = interstitialAd
             val elapsedMs = SystemClock.elapsedRealtime() - InterstitialFrequency.lastShownAtMs
             if (ad == null || elapsedMs < InterstitialFrequency.MIN_INTERVAL_MS) {
                 if (ad == null && !isLoading) loadKey++
                 onContinue()
                 return@showOrContinue
             }
             interstitialAd = null
             shownAd = ad
             ad.setAdEventListener(object : InterstitialAdEventListener {
                 override fun onAdShown() {
                     InterstitialFrequency.lastShownAtMs = SystemClock.elapsedRealtime()
                 }
                 override fun onAdFailedToShow(adError: AdError) = onFinished()
                 override fun onAdDismissed() = onFinished()
                 override fun onAdClicked() = Unit
                 override fun onAdImpression(impressionData: ImpressionData?) = Unit
             })
             FullscreenAdState.isFullscreenAdShowing = true
             ad.show(activity)
         }
     }
     ```

3. **Register for ad events**
   - [ ] The listener is set right before `show`; it records the show time in
     `onAdShown`, so a failed show does not block the next one.

4. **Show the ad at the transition point if it is loaded**
   - [ ] Taps while the ad is on screen are ignored; without a loaded ad or
     before the interval passes the transition continues immediately.

5. **Release the shown ad and load the next one**
   - [ ] `onFinished()` resets the flag, loads the next ad and continues the
     transition exactly once.

## Verify the build

- [ ] Run `./gradlew assembleDebug` (fallback `gradle assembleDebug`). Fix any
  Yandex SDK related compile errors.

### Links

Additional documentation:

- https://ads.yandex.com/helpcenter/en/dev/android/compose/interstitial.md
