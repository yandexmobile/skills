# AI Integration Agent Instructions for Android Rewarded Ads with Jetpack Compose

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
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.util.Log
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.LifecycleStartEffect
import com.yandex.mobile.ads.common.AdError
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.common.ImpressionData
import com.yandex.mobile.ads.compose.rememberRewardedAdLoader
import com.yandex.mobile.ads.rewarded.Reward
import com.yandex.mobile.ads.rewarded.RewardedAd
import com.yandex.mobile.ads.rewarded.RewardedAdEventListener
import com.yandex.mobile.ads.rewarded.RewardedAdLoadResult
```

## Method Signatures

```kotlin
@Composable
fun rememberRewardedAdLoader(): RewardedAdLoaderState

RewardedAdLoaderState.loadAd(adRequest: AdRequest): RewardedAdLoadResult  // suspend
RewardedAdLoadResult.Success(ad: RewardedAd) / Failure(error: AdRequestError)
RewardedAd.show(activity: Activity)
```

## Gotchas

- **Main thread:** the SDK API and all its callbacks are `@MainThread`.
- **Failed load.** Only log it; the next time the screen starts it loads
  again.
- **Screen recreated under the ad.** The ad runs in a separate activity, so the
  screen can be recreated while it is on screen (rotation, a creative that
  changes orientation, "Don't keep activities"). `onReward` should write to a
  persistent store; for full reliability keep the show logic in a
  `ViewModel` or an app-level object. The old listener is cleared in
  `onDispose`.

## Rewarded workflow

Names such as `TAG`, `onReward` or `REWARDED_AD_UNIT_ID` are placeholders; use
the app's own names and declare constants at the top of the file.

1. **Choose the control that offers the reward and the reward itself**
   - [ ] Grant the reward the user asked for; use `reward.amount` and
     `reward.type` only if the user says it is configured on the ad unit. If
     the request does not name the reward and its amount, ask.
   - [ ] Declare once per app, in the app's `ads` package, one file per
     declaration; skip what already exists:

     ```kotlin
     object FullscreenAdState {
         var isFullscreenAdShowing = false
     }

     tailrec fun Context.findActivity(): Activity = when (this) {
         is Activity -> this
         is ContextWrapper -> baseContext.findActivity()
         else -> error("No Activity in the context chain")
     }
     ```

2. **Create one ad loader and load the ad in advance**
   - [ ] Add this composable where the offer is shown:

     ```kotlin
     @Composable
     fun WatchAdButton(onReward: () -> Unit) {
         val activity = LocalContext.current.findActivity()
         val loader = rememberRewardedAdLoader()
         var rewardedAd by remember { mutableStateOf<RewardedAd?>(null) }
         var isLoading by remember { mutableStateOf(false) }
         var shownAd by remember { mutableStateOf<RewardedAd?>(null) }
         var loadKey by remember { mutableIntStateOf(0) }

         LaunchedEffect(loadKey) {
             if (loadKey == 0) return@LaunchedEffect
             isLoading = true
             when (val result = loader.loadAd(AdRequest.Builder(REWARDED_AD_UNIT_ID).build())) {
                 is RewardedAdLoadResult.Success -> rewardedAd = result.ad
                 is RewardedAdLoadResult.Failure -> Log.w(TAG, result.error.description)
             }
             isLoading = false
         }
         LifecycleStartEffect(Unit) {
             if (rewardedAd == null && !isLoading && shownAd == null) loadKey++
             onStopOrDispose { }
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
         }

         Button(enabled = rewardedAd != null && shownAd == null, onClick = {
             val ad = rewardedAd ?: return@Button
             if (FullscreenAdState.isFullscreenAdShowing) return@Button
             rewardedAd = null
             shownAd = ad
             ad.setAdEventListener(object : RewardedAdEventListener {
                 override fun onAdShown() = Unit
                 override fun onAdFailedToShow(adError: AdError) = onFinished()
                 override fun onAdDismissed() = onFinished()
                 override fun onAdClicked() = Unit
                 override fun onAdImpression(impressionData: ImpressionData?) = Unit
                 override fun onRewarded(reward: Reward) = onReward()
             })
             FullscreenAdState.isFullscreenAdShowing = true
             ad.show(activity)
         }) { Text("Watch an ad for a reward") }
     }
     ```

3. **Register for ad events and grant the reward in the reward callback**
   - [ ] The listener is set right before `show`; the reward is granted only
     in `onRewarded`.

4. **Show the ad when the user taps the control**
   - [ ] The button is enabled only while an ad is loaded and not on screen.

5. **Release the shown ad and load the next one**
   - [ ] `onFinished()` resets the flag and loads the next ad.

## Verify the build

- [ ] Run `./gradlew assembleDebug` (fallback `gradle assembleDebug`). Fix any
  Yandex SDK related compile errors.

### Links

Additional documentation:

- https://ads.yandex.com/helpcenter/en/dev/android/compose/rewarded.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-rewarded
