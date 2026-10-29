# AI Integration Agent Instructions for Android Rewarded Ads with Views

## Required Imports

```kotlin
import android.util.Log
import com.yandex.mobile.ads.common.AdError
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.common.AdRequestError
import com.yandex.mobile.ads.common.ImpressionData
import com.yandex.mobile.ads.rewarded.Reward
import com.yandex.mobile.ads.rewarded.RewardedAd
import com.yandex.mobile.ads.rewarded.RewardedAdEventListener
import com.yandex.mobile.ads.rewarded.RewardedAdLoadListener
import com.yandex.mobile.ads.rewarded.RewardedAdLoader
```

## Method Signatures

Java uses the same classes. Kotlin also has a suspend `loadAd(adRequest)`.
`Reward` has `amount: Int` and `type: String`.

## Gotchas

- **Main thread:** the SDK API and all its callbacks are `@MainThread`.
- **Application context for the loader**; `show(activity)` takes the
  activity. A failed load is only logged; the next `onStart` loads again.
- **Screen recreated under the ad.** The ad runs in a separate activity, so the
  screen below can be recreated while it is on screen (rotation, a creative
  that changes orientation, "Don't keep activities"). Grant the reward
  through a persistent store (saved balance, backend), not through views; for
  full reliability keep the show logic in a `ViewModel` or an app-level
  object. The old listener is cleared in `onDestroy`.
- **Fragment.** Keep the loader and the ad at the fragment level (create in
  `onCreate`, release in `onDestroy`), not in `onViewCreated` /
  `onDestroyView`, or the ad is thrown away when the fragment goes to the back
  stack. Show with `ad.show(requireActivity())`. The button belongs to the
  view: assign it in `onViewCreated`, null it in `onDestroyView`, update it
  with `?.`.

## Rewarded workflow

Names such as `TAG`, `watchAdButton`, `grantReward` or `REWARDED_AD_UNIT_ID`
are placeholders; use the app's own names and declare constants at the top of
the file.

1. **Choose the control that offers the reward and the reward itself**
   - [ ] A button such as "Watch an ad for 50 coins". Grant the reward the
     user asked for; use `reward.amount` and `reward.type` only if the user
     says the reward is configured on the ad unit. If the request does not
     name the reward and its amount, ask.
   - [ ] Declare once per app, in the app's `ads` package, one file per
     object; skip if it already exists:

     ```kotlin
     object FullscreenAdState {
         var isFullscreenAdShowing = false
     }
     ```

2. **Create one ad loader and load the ad in advance**
   - [ ] Add these fields to the activity with the button:

     ```kotlin
     private var rewardedAdLoader: RewardedAdLoader? = null
     private var rewardedAd: RewardedAd? = null
     private var shownRewardedAd: RewardedAd? = null
     private var isLoading = false
     private var isShowing = false
     ```

   - [ ] Add to `onCreate`, and call `loadRewardedAd()` in `onStart`:

     ```kotlin
     rewardedAdLoader = RewardedAdLoader(applicationContext)
     watchAdButton.setOnClickListener { showRewardedAd() }
     updateRewardButton()
     ```

   - [ ] Add the functions. The button is enabled only while an ad is loaded
     and not on screen:

     ```kotlin
     private fun loadRewardedAd() {
         if (isLoading || isShowing || rewardedAd != null) return
         isLoading = true
         rewardedAdLoader?.loadAd(
             adRequest = AdRequest.Builder(REWARDED_AD_UNIT_ID).build(),
             listener = object : RewardedAdLoadListener {
                 override fun onAdLoaded(rewarded: RewardedAd) {
                     isLoading = false
                     rewardedAd = rewarded
                     updateRewardButton()
                 }
                 override fun onAdFailedToLoad(error: AdRequestError) {
                     isLoading = false
                     Log.w(TAG, "Rewarded failed to load: ${error.description}")
                 }
             },
         )
     }

     private fun updateRewardButton() {
         watchAdButton.isEnabled = rewardedAd != null && !isShowing
     }
     ```

3. **Register for ad events and grant the reward in the reward callback**
   - [ ] Add this field:

     ```kotlin
     private val rewardedAdEventListener = object : RewardedAdEventListener {
         override fun onAdShown() = Unit
         override fun onAdFailedToShow(adError: AdError) = onRewardedFinished()
         override fun onAdDismissed() = onRewardedFinished()
         override fun onAdClicked() = Unit
         override fun onAdImpression(impressionData: ImpressionData?) = Unit
         override fun onRewarded(reward: Reward) = grantReward()
     }
     ```

4. **Show the ad when the user taps the control**
   - [ ] Add the function:

   ```kotlin
   private fun showRewardedAd() {
       val ad = rewardedAd ?: return
       if (FullscreenAdState.isFullscreenAdShowing) return
       rewardedAd = null
       shownRewardedAd = ad
       isShowing = true
       updateRewardButton()
       ad.setAdEventListener(rewardedAdEventListener)
       FullscreenAdState.isFullscreenAdShowing = true
       ad.show(this)
   }
   ```

5. **Release the shown ad and load the next one**
   - [ ] Add the function, and add the lines below to `onDestroy`:

     ```kotlin
     private fun onRewardedFinished() {
         isShowing = false
         shownRewardedAd = null
         FullscreenAdState.isFullscreenAdShowing = false
         updateRewardButton()
         loadRewardedAd()
     }
     ```

     ```kotlin
     if (isShowing) FullscreenAdState.isFullscreenAdShowing = false
     shownRewardedAd?.setAdEventListener(null)
     rewardedAdLoader?.cancelLoading()
     ```

## Verify the build

- [ ] Run `./gradlew assembleDebug` (fallback `gradle assembleDebug`). Fix any
  Yandex SDK related compile errors.

### Links

Additional documentation:

- https://ads.yandex.com/helpcenter/en/dev/android/rewarded.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-rewarded
