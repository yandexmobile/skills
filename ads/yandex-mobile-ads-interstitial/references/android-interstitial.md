# AI Integration Agent Instructions for Android Interstitial Ads with Views

## Required Imports

```kotlin
import android.os.SystemClock
import android.util.Log
import com.yandex.mobile.ads.common.AdError
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.common.AdRequestError
import com.yandex.mobile.ads.common.ImpressionData
import com.yandex.mobile.ads.interstitial.InterstitialAd
import com.yandex.mobile.ads.interstitial.InterstitialAdEventListener
import com.yandex.mobile.ads.interstitial.InterstitialAdLoadListener
import com.yandex.mobile.ads.interstitial.InterstitialAdLoader
```

## Method Signatures

Java uses the same classes. Kotlin also has a suspend `loadAd(adRequest)`
returning `InterstitialAdLoadResult.Success(ad)` or `Failure(error)`.

## Gotchas

- **Main thread:** the SDK API and all its callbacks are `@MainThread`.
- **Application context for the loader**; `show(activity)` takes the
  activity. A failed load is only logged; the next transition loads again.
- **Screen recreated under the ad.** The ad runs in a separate activity, so the
  screen below can be recreated while it is on screen (rotation, a creative
  that changes orientation, "Don't keep activities"). The old listener would
  still fire; it is cleared in `onDestroy`, so the transition is lost. If that
  matters, keep the show logic in a `ViewModel` or an app-level object.
- **Fragment.** Keep the loader and the ad at the fragment level (create in
  `onCreate`, release in `onDestroy`), not in `onViewCreated` /
  `onDestroyView`, or the ad is thrown away when the fragment goes to the back
  stack. Show with `ad.show(requireActivity())`.

## Interstitial workflow

Names such as `TAG`, `openNextLevel` or `INTERSTITIAL_AD_UNIT_ID` are
placeholders; use the app's own names and declare constants at the top of the
file.

1. **Choose the transition point where the ad is shown**
   - [ ] For example level completion: call
     `showInterstitialOrContinue { openNextLevel() }` there (step 4).
   - [ ] Declare these objects once per app, in the app's `ads` package, one file per
     object; skip any that already exists.
     `MIN_INTERVAL_MS` is the value from the user:

     ```kotlin
     object FullscreenAdState {
         var isFullscreenAdShowing = false
     }

     object InterstitialFrequency {
         const val MIN_INTERVAL_MS = 60_000L
         var lastShownAtMs = -MIN_INTERVAL_MS
     }
     ```

2. **Create one ad loader and load the ad in advance**
   - [ ] Add these fields to the activity with the transition point:

     ```kotlin
     private var interstitialAdLoader: InterstitialAdLoader? = null
     private var loadedInterstitialAd: InterstitialAd? = null
     private var shownInterstitialAd: InterstitialAd? = null
     private var isLoading = false
     private var pendingTransition: (() -> Unit)? = null
     ```

   - [ ] Add to `onCreate`:

     ```kotlin
     interstitialAdLoader = InterstitialAdLoader(applicationContext)
     loadInterstitialAd()
     ```

   - [ ] Add the function:

     ```kotlin
     private fun loadInterstitialAd() {
         if (isLoading || loadedInterstitialAd != null) return
         isLoading = true
         interstitialAdLoader?.loadAd(
             adRequest = AdRequest.Builder(INTERSTITIAL_AD_UNIT_ID).build(),
             listener = object : InterstitialAdLoadListener {
                 override fun onAdLoaded(interstitialAd: InterstitialAd) {
                     isLoading = false
                     loadedInterstitialAd = interstitialAd
                 }
                 override fun onAdFailedToLoad(error: AdRequestError) {
                     isLoading = false
                     Log.w(TAG, "Interstitial failed to load: ${error.description}")
                 }
             },
         )
     }
     ```

3. **Register for ad events**
   - [ ] Add this field; the show time is recorded in `onAdShown`:

     ```kotlin
     private val interstitialAdEventListener = object : InterstitialAdEventListener {
         override fun onAdShown() {
             InterstitialFrequency.lastShownAtMs = SystemClock.elapsedRealtime()
         }
         override fun onAdFailedToShow(adError: AdError) = onInterstitialFinished()
         override fun onAdDismissed() = onInterstitialFinished()
         override fun onAdClicked() = Unit
         override fun onAdImpression(impressionData: ImpressionData?) = Unit
     }
     ```

4. **Show the ad at the transition point if it is loaded**
   - [ ] Add the function:

     ```kotlin
     private fun showInterstitialOrContinue(continueTransition: () -> Unit) {
         if (pendingTransition != null) return
         val ad = loadedInterstitialAd
         val elapsedMs = SystemClock.elapsedRealtime() - InterstitialFrequency.lastShownAtMs
         if (ad == null || elapsedMs < InterstitialFrequency.MIN_INTERVAL_MS) {
             loadInterstitialAd()
             continueTransition()
             return
         }
         loadedInterstitialAd = null
         shownInterstitialAd = ad
         pendingTransition = continueTransition
         ad.setAdEventListener(interstitialAdEventListener)
         FullscreenAdState.isFullscreenAdShowing = true
         ad.show(this)
     }
     ```

5. **Release the shown ad and load the next one**
   - [ ] Add the function; the transition continues exactly once:

     ```kotlin
     private fun onInterstitialFinished() {
         shownInterstitialAd = null
         FullscreenAdState.isFullscreenAdShowing = false
         val transition = pendingTransition
         pendingTransition = null
         transition?.invoke()
         loadInterstitialAd()
     }
     ```

   - [ ] Add to `onDestroy`:

     ```kotlin
     if (pendingTransition != null) FullscreenAdState.isFullscreenAdShowing = false
     pendingTransition = null
     shownInterstitialAd?.setAdEventListener(null)
     interstitialAdLoader?.cancelLoading()
     ```

## Verify the build

- [ ] Run `./gradlew assembleDebug` (fallback `gradle assembleDebug`). Fix any
  Yandex SDK related compile errors.

### Links

Additional documentation:

- https://ads.yandex.com/helpcenter/en/dev/android/interstitial.md
