# AI Integration Agent Instructions for Android Banner Ads with Views

## Required Imports

```kotlin
import android.util.Log
import android.widget.FrameLayout
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.doOnLayout
import androidx.core.view.updatePadding
import com.yandex.mobile.ads.banner.BannerAdEventListener
import com.yandex.mobile.ads.banner.BannerAdSize
import com.yandex.mobile.ads.banner.BannerAdView
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.common.AdRequestError
import com.yandex.mobile.ads.common.ImpressionData
import kotlin.math.roundToInt
```

## Method Signatures

Java uses the same classes; the `BannerAdSize` factories are static there.
Widths and heights are in dp:

```kotlin
BannerAdSize.sticky(context: Context, width: Int): BannerAdSize
BannerAdSize.inline(context: Context, width: Int, maxHeight: Int): BannerAdSize
```

## Gotchas

- **Main thread:** the SDK API and all its callbacks are `@MainThread`.
- **Activity context.** `BannerAdView` and `BannerAdSize` take the activity.
- **`setAdSize` works once.** For a new size (for example after rotation)
  destroy the view and create a new `BannerAdView`.
- **Failed load.** Only log it. The next `onStart` loads again if the banner
  never loaded; a loaded banner refreshes itself.
- **Mediation.** With mediation adapters, compute `BannerAdSize.sticky` after
  `YandexAds.initialize` has completed; before that the size is preliminary.
- **Edge-to-edge.** With `targetSdk` 35+ a bottom banner draws under the
  navigation bar; the container applies the system bar insets (step 2).
- **Inline banners in a list.** Keep one `BannerAdView` per ad slot outside
  the `ViewHolder`, move it into the holder's container on bind (remove it
  from its old parent first), and destroy all of them with the screen.
- **Fragment.** Do the same in the fragment; destroy the view in
  `onDestroyView`.
- **Video in inline banners** needs hardware acceleration. If the app disables
  it, enable it for the activities that show ads.

## Banner workflow

Names such as `TAG`, `BANNER_AD_UNIT_ID` or `ad_container` are placeholders;
use the app's own names and declare constants at the top of the file.

1. **Choose the placement and the banner type**
   - [ ] Sticky (default) for a screen edge, inline inside an article. Add a
     container to the screen layout, for example a `FrameLayout`
     `@+id/ad_container` with `match_parent` width and `wrap_content` height
     at the bottom.

2. **Create the ad view with the size computed from the container width**
   - [ ] Add these fields to the activity that shows the banner:

     ```kotlin
     private var bannerAdView: BannerAdView? = null
     private var isLoading = false
     private var hasLoaded = false
     ```

   - [ ] Add to `onCreate` after `setContentView`; skip the insets listener if
     the app already handles them:

     ```kotlin
     val adContainer = findViewById<FrameLayout>(R.id.ad_container)
     ViewCompat.setOnApplyWindowInsetsListener(adContainer) { view, insets ->
         view.updatePadding(
             bottom = insets.getInsets(WindowInsetsCompat.Type.systemBars()).bottom,
         )
         insets
     }
     adContainer.doOnLayout { createBanner(adContainer) }
     ```

   - [ ] Add the function. Inline: `BannerAdSize.inline(context = this,
     width = widthDp, maxHeight = maxHeightDp)` with, for example, a third of
     the screen height.

     ```kotlin
     private fun createBanner(container: FrameLayout) {
         val widthPx = container.width - container.paddingLeft - container.paddingRight
         val banner = BannerAdView(this)
         banner.setAdSize(
             BannerAdSize.sticky(
                 context = this,
                 width = (widthPx / resources.displayMetrics.density).roundToInt(),
             ),
         )
         banner.setBannerAdEventListener(bannerAdEventListener)
         container.addView(banner)
         bannerAdView = banner
         loadBanner()
     }
     ```

3. **Register for ad events**
   - [ ] Add this field:

     ```kotlin
     private val bannerAdEventListener = object : BannerAdEventListener {
         override fun onAdLoaded() {
             isLoading = false
             hasLoaded = true
         }
         override fun onAdFailedToLoad(error: AdRequestError) {
             isLoading = false
             Log.w(TAG, "Banner failed to load: ${error.description}")
         }
         override fun onAdClicked() = Unit
         override fun onImpression(impressionData: ImpressionData?) = Unit
     }
     ```

4. **Load the ad**
   - [ ] Add the function:

     ```kotlin
     private fun loadBanner() {
         val banner = bannerAdView ?: return
         isLoading = true
         banner.loadAd(AdRequest.Builder(BANNER_AD_UNIT_ID).build())
     }
     ```

   - [ ] Add to `onStart`, so a failed banner loads again when the screen is
     shown again:

     ```kotlin
     if (!hasLoaded && !isLoading) loadBanner()
     ```

5. **Release the ad view with its screen**
   - [ ] Add to `onDestroy`:

     ```kotlin
     bannerAdView?.destroy()
     ```

## Verify the build

- [ ] Run `./gradlew assembleDebug` (fallback `gradle assembleDebug`). Fix any
  Yandex SDK related compile errors.

### Links

Additional documentation:

- https://ads.yandex.com/helpcenter/en/dev/android/adaptive-sticky-banner.md
- https://ads.yandex.com/helpcenter/en/dev/android/adaptive-inline-banner.md
