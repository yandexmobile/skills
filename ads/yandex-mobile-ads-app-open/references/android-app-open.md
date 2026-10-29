# AI Integration Agent Instructions for Android App Open Ads

## Required Imports

```kotlin
import android.app.Activity
import android.app.Application
import android.content.res.Configuration
import android.os.Bundle
import android.os.SystemClock
import android.util.Log
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import com.yandex.mobile.ads.appopenad.AppOpenAd
import com.yandex.mobile.ads.appopenad.AppOpenAdEventListener
import com.yandex.mobile.ads.appopenad.AppOpenAdLoadListener
import com.yandex.mobile.ads.appopenad.AppOpenAdLoader
import com.yandex.mobile.ads.common.AdError
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.common.AdRequestError
import com.yandex.mobile.ads.common.ImpressionData
import com.yandex.mobile.ads.common.YandexAds
```

## Method Signatures

Java uses the same classes. Kotlin also has a suspend `loadAd(adRequest)`;
Compose apps use the same manager.

## Gotchas

- **Main thread:** the SDK API and all its callbacks are `@MainThread`.
- **No load at app start.** The first load happens when the app first goes
  to background, not in parallel with the other formats at startup. A failed
  load is only logged; the next return loads again.
- **Cold start.** By default the first show happens on a later return; tell
  the user this in the final message. Only with a splash screen, hold it for
  a short timeout (about 3 s) and show the ad from the splash if it loads.
- **Frequency rule.** If the user gave one (no shows in the first sessions,
  minimum interval between shows), add a check before `show`.
- **Dependency.** `androidx.lifecycle:lifecycle-process`, in the
  `androidx.lifecycle` version already resolved in the project:
  `./gradlew :app:dependencies --configuration debugRuntimeClasspath | grep lifecycle`.

## App open workflow

Names such as `TAG`, `APP_OPEN_AD_UNIT_ID` or `MIN_BACKGROUND_MS` (30 seconds
unless the user asks otherwise) are placeholders; use the app's own names and
declare constants at the top of the file.

1. **Create an app-level manager that owns the ad loader**
   - [ ] Declare once per app, in the app's `ads` package, one file per
     object; skip if it already exists:

     ```kotlin
     object FullscreenAdState {
         var isFullscreenAdShowing = false
     }
     ```

   - [ ] The manager:

     ```kotlin
     class AppOpenAdManager(application: Application) :
         DefaultLifecycleObserver, Application.ActivityLifecycleCallbacks {

         private val appOpenAdLoader = AppOpenAdLoader(application)
         private val appOpenAdEventListener = object : AppOpenAdEventListener {
             override fun onAdShown() = Unit
             override fun onAdFailedToShow(adError: AdError) = onAdFinished()
             override fun onAdDismissed() = onAdFinished()
             override fun onAdClicked() = Unit
             override fun onAdImpression(impressionData: ImpressionData?) = Unit
         }
         private var appOpenAd: AppOpenAd? = null
         private var currentActivity: Activity? = null
         private var backgroundedAtMs: Long? = null
         private var isSdkInitialized = false
         private var isLoading = false

         fun startObserving(application: Application) {
             application.registerActivityLifecycleCallbacks(this)
             ProcessLifecycleOwner.get().lifecycle.addObserver(this)
         }
     ```

2. **Load the ad after the SDK is initialized**
   - [ ] Keep the existing `YandexAds.initialize` call in
     `Application.onCreate`; add the manager before it and the call into its
     callback:

     ```kotlin
     val appOpenAdManager = AppOpenAdManager(this)
     appOpenAdManager.startObserving(this)
     YandexAds.initialize(context = this) {
         appOpenAdManager.onSdkInitialized()
     }
     ```

   - [ ] Add to the manager:

     ```kotlin
         fun onSdkInitialized() {
             isSdkInitialized = true
         }

         private fun loadAd() {
             if (!isSdkInitialized || isLoading || appOpenAd != null) return
             isLoading = true
             appOpenAdLoader.loadAd(
                 adRequest = AdRequest.Builder(APP_OPEN_AD_UNIT_ID).build(),
                 listener = object : AppOpenAdLoadListener {
                     override fun onAdLoaded(appOpenAd: AppOpenAd) {
                         isLoading = false
                         this@AppOpenAdManager.appOpenAd = appOpenAd
                     }
                     override fun onAdFailedToLoad(error: AdRequestError) {
                         isLoading = false
                         Log.w(TAG, "App open ad failed to load: ${error.description}")
                     }
                 },
             )
         }
     ```

3. **Detect the moment the app comes to the foreground**

   - [ ] Add to the manager:

     ```kotlin
         override fun onActivityStarted(activity: Activity) {
             currentActivity = activity
         }
         override fun onActivityDestroyed(activity: Activity) {
             if (currentActivity === activity) currentActivity = null
         }
         override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) = Unit
         override fun onActivityResumed(activity: Activity) = Unit
         override fun onActivityPaused(activity: Activity) = Unit
         override fun onActivityStopped(activity: Activity) = Unit
         override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit

         override fun onStop(owner: LifecycleOwner) {
             backgroundedAtMs = SystemClock.elapsedRealtime()
             loadAd()
         }

         override fun onStart(owner: LifecycleOwner) {
             val backgroundedAt = backgroundedAtMs ?: return
             val activity = currentActivity
             val wasInBackgroundLongEnough = SystemClock.elapsedRealtime() - backgroundedAt >= MIN_BACKGROUND_MS
             if (activity != null && wasInBackgroundLongEnough) showAdIfAvailable(activity) else loadAd()
         }
     ```

4. **Show the ad if it is loaded and nothing from the rules forbids it**
   - [ ] Portrait only, never over another full-screen ad:

     ```kotlin
         private fun showAdIfAvailable(activity: Activity) {
             val ad = appOpenAd ?: return loadAd()
             val isPortrait = activity.resources.configuration.orientation == Configuration.ORIENTATION_PORTRAIT
             if (FullscreenAdState.isFullscreenAdShowing || !isPortrait) return
             FullscreenAdState.isFullscreenAdShowing = true
             ad.setAdEventListener(appOpenAdEventListener)
             ad.show(activity)
         }
     ```

5. **Make the interstitial and rewarded ads already in the app set the flag**
   - [ ] In each existing integration set
     `FullscreenAdState.isFullscreenAdShowing = true` right before `show` and
     `false` in `onAdDismissed`, `onAdFailedToShow` and when the screen is
     destroyed while the ad is on screen.

6. **Release the shown ad and load the next one**

   - [ ] Add to the manager:

     ```kotlin
         private fun onAdFinished() {
             appOpenAd = null
             FullscreenAdState.isFullscreenAdShowing = false
             loadAd()
         }
     }
     ```

## Verify the build

- [ ] Run `./gradlew assembleDebug` (fallback `gradle assembleDebug`). Fix any
  Yandex SDK related compile errors.

### Links

Additional documentation:

- https://ads.yandex.com/helpcenter/en/dev/android/app-open-ad.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-app-open
- https://ads.yandex.com/helpcenter/en/dev/android/compose/app-open-ad.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-app-open
