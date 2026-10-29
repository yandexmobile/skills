# AI Integration Agent Instructions for Android Native Ads with Views

## Required Imports

```kotlin
import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.widget.AppCompatRatingBar
import androidx.core.view.isVisible
import androidx.recyclerview.widget.RecyclerView
import com.yandex.mobile.ads.common.AdBindingResult
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.common.AdRequestError
import com.yandex.mobile.ads.nativeads.NativeAd
import com.yandex.mobile.ads.nativeads.NativeAdView
import com.yandex.mobile.ads.nativeads.NativeAdViewBinder
import com.yandex.mobile.ads.nativeads.NativeBulkAdLoadListener
import com.yandex.mobile.ads.nativeads.NativeBulkAdLoader
import com.yandex.mobile.ads.nativeads.Rating
```

## Method Signatures

Java uses the same classes. `NativeAdLoader(context).loadAd(adRequest, listener)`
loads one ad (`NativeAdLoadListener.onAdLoaded(nativeAd: NativeAd)`).

```kotlin
NativeBulkAdLoader(context: Context)
fun loadAds(adRequest: AdRequest, adsCount: Int, listener: NativeBulkAdLoadListener)
fun cancelLoading()
NativeAd.bindNativeAd(viewBinder: NativeAdViewBinder): AdBindingResult
AdBindingResult.Success / Failure(missingAssetName: String?, exception: Throwable)
```

## Gotchas

- **Main thread:** the SDK API and all its callbacks are `@MainThread`.
- **Application context for the loaders**; they need no window.
- **No SDK templates in 8.x.** Build the layout yourself; the sample's
  `native_banner_ad_view.xml` is a ready starting point.
- **Every asset needs a view.** Which assets an ad contains differs from ad to
  ad (https://ads.yandex.com/helpcenter/en/dev/android/components.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-native). A
  missing view makes binding fail on real traffic even if demo ads render; a
  hidden or too small view binds, but the impression is not counted. Do not
  hide asset views yourself.
- **Display requirements.** The ad view and asset views are opaque and lie
  inside the ad view. Do not change ad texts or images; scale images keeping
  the aspect ratio, cropping at most 20%.
- **Video.** `MediaView` must be at least 300 × 160 dp; video needs hardware
  acceleration.
- **Strong reference.** Keep loaded ads referenced (the adapter items) while
  they are on screen.
- **Failed load.** Only log it; the next `onStart` loads again.
- **One slot.** Use `NativeAdLoader(applicationContext).loadAd(adRequest = …,
  listener = …)`, keep the `NativeAd` in a field, put the layout on the screen
  with `<include layout="@layout/native_ad" />` and an id on its root, and
  bind once with
  `bindNativeAd(binder = createNativeAdViewBinder(view), nativeAd = nativeAd)`.
- **Fragment.** Keep the loader and the adapter with the inserted ads at the
  fragment level (`onCreate` / `onDestroy`); attach the adapter to the
  `RecyclerView` in `onViewCreated` and set `recyclerView.adapter = null` in
  `onDestroyView`.

## Native workflow

Names such as `TAG`, `feedAdapter` or `NATIVE_BULK_AD_UNIT_ID` are
placeholders; use the app's own names, rename
layout ids to the app's convention and replace `com.example.app` with the
app's package.

1. **Choose the placement and how many ads it needs**
   - [ ] A feed (main case): `NativeBulkAdLoader` with
     `demo-native-bulk-yandex` (up to 9 ads per request), an ad after every
     N-th item, loaded once in advance.

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
   - [ ] Add these fields and the function to the activity with the feed.
     Create the loader in `onCreate`
     (`bulkAdLoader = NativeBulkAdLoader(applicationContext)`), call
     `loadFeedAds()` in `onStart` and `bulkAdLoader?.cancelLoading()` in
     `onDestroy`. At the top of the file, `FEED_ADS_COUNT` is min(9, number of
     ad slots in the list):

     ```kotlin
     private const val FEED_ADS_COUNT = 3
     ```

     ```kotlin
     private var bulkAdLoader: NativeBulkAdLoader? = null
     private var isLoading = false
     private var hasAds = false

     private fun loadFeedAds() {
         if (isLoading || hasAds) return
         isLoading = true
         bulkAdLoader?.loadAds(
             adRequest = AdRequest.Builder(NATIVE_BULK_AD_UNIT_ID).build(),
             adsCount = FEED_ADS_COUNT,
             listener = object : NativeBulkAdLoadListener {
                 override fun onAdsLoaded(nativeAds: List<NativeAd>) {
                     isLoading = false
                     hasAds = feedAdapter.insertAds(nativeAds) > 0
                 }
                 override fun onAdsFailedToLoad(error: AdRequestError) {
                     isLoading = false
                     Log.w(TAG, "Feed ads failed to load: ${error.description}")
                 }
             },
         )
     }
     ```

4. **Bind the loaded ad to the layout and handle a binding failure**
   - [ ] Declare these functions once in the `ads` package. On `Failure` the
     row is hidden:

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

   - [ ] Add an ad row type to the app's adapter. An ad goes after every
     `AD_INTERVAL` items, only as many as fit the current content; if none
     fit (content still loading), `hasAds` stays false and the next `onStart`
     loads again. The binder is created once per view holder and reused:

     ```kotlin
     sealed interface FeedItem {
         class Content(val text: String) : FeedItem
         class Ad(val nativeAd: NativeAd) : FeedItem
     }

     class NativeAdViewHolder(val nativeAdView: NativeAdView) : RecyclerView.ViewHolder(nativeAdView) {
         val binder = createNativeAdViewBinder(nativeAdView)
     }

     class FeedAdapter(private val items: MutableList<FeedItem>) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

         fun insertAds(nativeAds: List<NativeAd>): Int {
             var insertedCount = 0
             for ((index, nativeAd) in nativeAds.withIndex()) {
                 val position = (index + 1) * AD_INTERVAL + index
                 if (position > items.size) break
                 items.add(position, FeedItem.Ad(nativeAd))
                 notifyItemInserted(position)
                 insertedCount++
             }
             return insertedCount
         }

         override fun getItemCount() = items.size

         override fun getItemViewType(position: Int) = if (items[position] is FeedItem.Ad) VIEW_TYPE_AD else 0

         override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
             if (viewType != VIEW_TYPE_AD) return object : RecyclerView.ViewHolder(TextView(parent.context)) {}
             val view = LayoutInflater.from(parent.context).inflate(R.layout.native_ad, parent, false)
             return NativeAdViewHolder(view as NativeAdView)
         }

         override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
             when (val item = items[position]) {
                 is FeedItem.Content -> (holder.itemView as TextView).text = item.text
                 is FeedItem.Ad -> {
                     val adHolder = holder as NativeAdViewHolder
                     adHolder.nativeAdView.isVisible = bindNativeAd(
                         binder = adHolder.binder,
                         nativeAd = item.nativeAd,
                     )
                 }
             }
         }

         private companion object {
             const val AD_INTERVAL = 8
             const val VIEW_TYPE_AD = 1
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

- https://ads.yandex.com/helpcenter/en/dev/android/native.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-native
- https://github.com/yandexmobile/yandex-ads-sdk-android/blob/master/YandexMobileAdsExample/app/src/main/res/layout/native_banner_ad_view.xml
