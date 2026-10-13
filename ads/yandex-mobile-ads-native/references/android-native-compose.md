# AI Integration Agent Instructions for Android Native Ads with Jetpack Compose

## Required Imports

The SDK has no Compose API for native ads: the ad is an XML layout hosted in
`AndroidView`. Only `mobileads` is needed (not `mobileads-compose`), plus
`androidx.lifecycle:lifecycle-runtime-compose` 2.7.0 or newer.

```kotlin
import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.view.LayoutInflater
import androidx.appcompat.widget.AppCompatRatingBar
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.view.isVisible
import androidx.lifecycle.compose.LifecycleStartEffect
import com.yandex.mobile.ads.common.AdBindingResult
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.nativeads.NativeAd
import com.yandex.mobile.ads.nativeads.NativeAdLoadResult
import com.yandex.mobile.ads.nativeads.NativeAdLoader
import com.yandex.mobile.ads.nativeads.NativeAdView
import com.yandex.mobile.ads.nativeads.NativeAdViewBinder
import com.yandex.mobile.ads.nativeads.Rating
```

## Method Signatures

`NativeAdLoader.loadAd(adRequest)` is a suspend function returning
`NativeAdLoadResult.Success(ad)` or `Failure(error)`;
`NativeBulkAdLoader.loadAds(adRequest, adsCount)` returns
`NativeBulkAdLoadResult.Success(ads)` (0 to `adsCount` ads) for lists.
`NativeAd.bindNativeAd(binder)` returns `AdBindingResult.Success` or
`Failure(missingAssetName, exception)`.

## Gotchas

- **Main thread:** the SDK API and all its callbacks are `@MainThread`.
- **Every asset needs a view.** Which assets an ad contains differs from ad to
  ad (https://ads.yandex.com/helpcenter/en/dev/android/components.md). A
  missing view makes binding fail on real traffic; a hidden or too small view
  binds, but the impression is not counted. Do not hide asset views yourself.
- **Display requirements.** The ad view and asset views are opaque and lie
  inside the ad view; do not change texts or images; scale images keeping the
  aspect ratio, cropping at most 20%. `MediaView` is at least 300 × 160 dp.
- **Bind once per ad:** `key(nativeAd)` plus binding in `factory`.
- **Failed load.** Only log it; the next time the screen starts it loads
  again.
- **Configuration change** reloads the ad; to keep it, load in a `ViewModel`
  with a loader created from the `Application`.
- **Lists.** Add only as many ad items to the `LazyColumn` as arrived.

## Native workflow

Names such as `TAG` or `NATIVE_AD_UNIT_ID` are placeholders; use the app's own
names, rename layout ids to the app's convention and replace `com.example.app`
with the app's package.

1. **Choose the placement and how many ads it needs**
   - [ ] One slot with `demo-native-app-yandex`, as below; a list uses
     `NativeBulkAdLoader` with `demo-native-bulk-yandex`.

2. **Create the ad layout with a view for every asset**
   - [ ] `res/layout/native_ad.xml`, styled freely, with all views and an
     opaque background:

     ```xml
     <com.yandex.mobile.ads.nativeads.NativeAdView xmlns:android="http://schemas.android.com/apk/res/android"
         android:layout_width="match_parent" android:layout_height="wrap_content"
         android:background="?android:attr/colorBackground">
         <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
             android:orientation="vertical" android:padding="12dp">
             <TextView android:id="@+id/sponsored" android:layout_width="wrap_content" android:layout_height="wrap_content" />
             <TextView android:id="@+id/age" android:layout_width="wrap_content" android:layout_height="wrap_content" />
             <ImageView android:id="@+id/feedback" android:layout_width="24dp" android:layout_height="24dp" />
             <ImageView android:id="@+id/icon" android:layout_width="48dp" android:layout_height="48dp" />
             <TextView android:id="@+id/title" android:layout_width="wrap_content" android:layout_height="wrap_content" />
             <TextView android:id="@+id/body" android:layout_width="wrap_content" android:layout_height="wrap_content" />
             <ImageView android:id="@+id/favicon" android:layout_width="16dp" android:layout_height="16dp" />
             <TextView android:id="@+id/domain" android:layout_width="wrap_content" android:layout_height="wrap_content" />
             <com.yandex.mobile.ads.nativeads.MediaView android:id="@+id/media"
                 android:layout_width="match_parent" android:layout_height="wrap_content" />
             <TextView android:id="@+id/price" android:layout_width="wrap_content" android:layout_height="wrap_content" />
             <com.example.app.RatingView android:id="@+id/rating" style="?android:attr/ratingBarStyleSmall"
                 android:layout_width="wrap_content" android:layout_height="wrap_content" android:numStars="5" />
             <TextView android:id="@+id/review_count" android:layout_width="wrap_content" android:layout_height="wrap_content" />
             <Button android:id="@+id/call_to_action" android:layout_width="wrap_content" android:layout_height="wrap_content" />
             <TextView android:id="@+id/warning" android:layout_width="match_parent" android:layout_height="wrap_content" />
         </LinearLayout>
     </com.yandex.mobile.ads.nativeads.NativeAdView>
     ```

     ```kotlin
     class RatingView @JvmOverloads constructor(
         context: Context,
         attrs: AttributeSet? = null,
     ) : AppCompatRatingBar(context, attrs), Rating
     ```

3. **Create one ad loader and load the ads**
   - [ ] Add this composable where the ad goes; it loads when the screen
     starts and again on the next start if there is no ad:

     ```kotlin
     @Composable
     fun NativeAdSlot(modifier: Modifier = Modifier) {
         val context = LocalContext.current
         val loader = remember { NativeAdLoader(context.applicationContext) }
         var nativeAd by remember { mutableStateOf<NativeAd?>(null) }
         var isLoading by remember { mutableStateOf(false) }
         var loadKey by remember { mutableIntStateOf(0) }

         LaunchedEffect(loadKey) {
             if (loadKey == 0) return@LaunchedEffect
             isLoading = true
             when (val result = loader.loadAd(AdRequest.Builder(NATIVE_AD_UNIT_ID).build())) {
                 is NativeAdLoadResult.Success -> nativeAd = result.ad
                 is NativeAdLoadResult.Failure -> Log.w(TAG, result.error.description)
             }
             isLoading = false
         }
         LifecycleStartEffect(Unit) {
             if (nativeAd == null && !isLoading) loadKey++
             onStopOrDispose { }
         }
         DisposableEffect(loader) { onDispose { loader.cancelLoading() } }

         val ad = nativeAd ?: return
         key(ad) {
             AndroidView(
                 modifier = modifier.fillMaxWidth(),
                 factory = { viewContext ->
                     val view = LayoutInflater.from(viewContext).inflate(R.layout.native_ad, null) as NativeAdView
                     view.isVisible = bindNativeAd(
                         binder = createNativeAdViewBinder(view),
                         nativeAd = ad,
                     )
                     view
                 },
             )
         }
     }
     ```

4. **Bind the loaded ad to the layout and handle a binding failure**
   - [ ] Declare these functions once in the `ads` package:

     ```kotlin
     fun createNativeAdViewBinder(view: NativeAdView): NativeAdViewBinder =
         NativeAdViewBinder.Builder(view)
             .setAgeView(view.findViewById(R.id.age))
             .setBodyView(view.findViewById(R.id.body))
             .setCallToActionView(view.findViewById(R.id.call_to_action))
             .setDomainView(view.findViewById(R.id.domain))
             .setFaviconView(view.findViewById(R.id.favicon))
             .setFeedbackView(view.findViewById(R.id.feedback))
             .setIconView(view.findViewById(R.id.icon))
             .setMediaView(view.findViewById(R.id.media))
             .setPriceView(view.findViewById(R.id.price))
             .setRatingView(view.findViewById<RatingView>(R.id.rating))
             .setReviewCountView(view.findViewById(R.id.review_count))
             .setSponsoredView(view.findViewById(R.id.sponsored))
             .setTitleView(view.findViewById(R.id.title))
             .setWarningView(view.findViewById(R.id.warning))
             .build()

     fun bindNativeAd(binder: NativeAdViewBinder, nativeAd: NativeAd): Boolean =
         when (val result = nativeAd.bindNativeAd(binder)) {
             is AdBindingResult.Success -> true
             is AdBindingResult.Failure -> {
                 Log.w(TAG, "Missing asset view: ${result.missingAssetName}", result.exception)
                 false
             }
         }
     ```

5. **Register for ad events**
   - [ ] Optional: `nativeAd.setNativeAdEventListener(...)` only if the app
     needs click or impression events for its analytics.

## Verify the build

- [ ] Run `./gradlew assembleDebug` (fallback `gradle assembleDebug`). Fix any
  Yandex SDK related compile errors.

### Links

Additional documentation:

- https://ads.yandex.com/helpcenter/en/dev/android/native.md
