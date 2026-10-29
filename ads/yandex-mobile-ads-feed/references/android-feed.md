# Feed Ad with Android Views

## Dependencies and public API

Use `com.yandex.android:mobileads` 8.x, or the app's existing mediation
dependency that supplies it, and AndroidX RecyclerView. No separate Feed
artifact is needed. Resolve a current compatible SDK when installing or
upgrading; do not copy an older version from an example.

SDK 8 uses `com.yandex.mobile.ads.common.AdRequest`, not the SDK 7
`FeedAdRequestConfiguration`. Feed callbacks are:

- `FeedAdLoadListener.onAdLoaded()`
- `FeedAdLoadListener.onAdFailedToLoad(error: AdRequestError)`
- `FeedAdEventListener.onAdClicked()`
- `FeedAdEventListener.onImpression(impressionData: ImpressionData?)`

Some documentation examples call the last method `onAdImpression`; the
SDK interface and public sample use **`onImpression`**. Verify the installed
interface before implementing overrides.

## Configure and display

Call the following screen-owned helper after SDK/privacy readiness. Pass
the Activity (or a themed context backed by it), not `applicationContext`,
so the SDK can observe host destruction. Measure the RecyclerView after
layout and convert its available width from pixels to dp, subtracting
padding and any item decoration that consumes horizontal space.

The helper owns one feed session. `contentAdapter` is optional: it appends
the ad sequence to existing content using `ConcatAdapter`.

```kotlin
import android.content.Context
import android.util.Log
import androidx.annotation.MainThread
import androidx.recyclerview.widget.ConcatAdapter
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.common.AdRequestError
import com.yandex.mobile.ads.common.ImpressionData
import com.yandex.mobile.ads.feed.FeedAd
import com.yandex.mobile.ads.feed.FeedAdAdapter
import com.yandex.mobile.ads.feed.FeedAdAppearance
import com.yandex.mobile.ads.feed.FeedAdEventListener
import com.yandex.mobile.ads.feed.FeedAdLoadListener

@MainThread
class FeedSession(
    context: Context,
    private val recyclerView: RecyclerView,
    cardWidthDp: Int,
    adUnitId: String = "demo-feed-yandex",
    contentAdapter: RecyclerView.Adapter<out RecyclerView.ViewHolder>? = null,
) {
    init {
        require(cardWidthDp > 0)
    }

    private val feed = FeedAd.Builder(
        context,
        AdRequest.Builder(adUnitId).build(),
        FeedAdAppearance.Builder(cardWidthDp)
            .setCardCornerRadius(16.0)
            .build(),
    ).build()
    private val feedAdapter = FeedAdAdapter(feed)

    init {
        feed.loadListener = object : FeedAdLoadListener {
            override fun onAdLoaded() {
                // Update screen load state if needed; the adapter updates itself.
            }

            override fun onAdFailedToLoad(error: AdRequestError) {
                Log.w("FeedAd", "Load failed: ${error.description}")
            }
        }
        feedAdapter.eventListener = object : FeedAdEventListener {
            override fun onAdClicked() {
                // Forward the SDK click event to the app's analytics.
            }

            override fun onImpression(impressionData: ImpressionData?) {
                // Forward impression data if needed; it may be null.
            }
        }
        // Preload once, before attaching the adapter (attachment can start loading).
        feed.preloadAd()
        recyclerView.layoutManager = LinearLayoutManager(context)
        recyclerView.adapter = if (contentAdapter == null) {
            feedAdapter
        } else {
            ConcatAdapter(contentAdapter, feedAdapter)
        }
    }

    fun release() {
        feed.loadListener = null
        feedAdapter.eventListener = null
        recyclerView.adapter = null
    }
}
```

Adapt the helper to the existing screen instead of replacing its layout
manager or adapter blindly. Retain the session in the Activity/Fragment view
owner and release that reference after `release()`. A Fragment should clear
it in `onDestroyView`; an Activity when its screen is disposed. For removing
only the feed while keeping content, remove the feed adapter from the
`ConcatAdapter` instead of clearing the entire RecyclerView.

For a RecyclerView without item decorations, the measurement is:

```kotlin
val widthPx = recyclerView.width - recyclerView.paddingLeft - recyclerView.paddingRight
val cardWidthDp = (widthPx / recyclerView.resources.displayMetrics.density).toInt()
```

Wait for `cardWidthDp > 0` and keep a guard against creating a second session
on unchanged layout. On a real width change, dispose the old session and
create a new one with the updated appearance.

## Paging, errors and lifetime

- `preloadAd()` starts the initial load once. Calling it again on the same
  feed can produce an already-started error; do not call it from
  `onAdLoaded`, `onBindViewHolder`, `onResume` or every recomposition.
- The SDK adapter observes feed data, renders its own loading row and starts
  subsequent loads as ads become visible. Do not call `submitList`,
  `notifyDataSetChanged` or implement your own paging for this adapter.
- `ConcatAdapter(contentAdapter, feedAdapter)` places Feed after all content;
  it does not insert individual ads every N rows. Keep the content adapter's
  behavior and its own item positions intact.
- A failed feed stops further loading. Leave existing cards/content visible.
  On an intentional later retry or screen re-entry, create a fresh
  `FeedAd`/`FeedAdAdapter` session; do not preload the failed instance again.
- Detach the adapter and clear listeners when discarding the screen. Use a
  fresh adapter for a newly created screen view rather than retaining a
  detached adapter or Activity context in an application singleton.
- Feed exposes no public `destroy()`/`cancelLoading()` method. Do not call
  internal view-model methods or copy native-loader cleanup APIs.

## Verify

- Run the app module's debug build (for example `./gradlew :app:assembleDebug`).
- Use `demo-feed-yandex` to check first load, later cards, clicks/impressions,
  failure with existing content, navigation away/back and width changes.
- Check standalone and appended placements as applicable; ensure no duplicate
  initial requests and no immediate retry loop.
- Inspect Logcat filtered by `YandexAds` for integration diagnostics:
  `adb logcat -v brief '*:S YandexAds'`.
- Report actual build/runtime results and remind the user to replace a demo
  ID before publishing.

## Sources

- [Feed integration](https://ads.yandex.com/helpcenter/en/dev/android/feed-ad?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-feed)
- [Public SDK sample](https://github.com/yandexmobile/yandex-ads-sdk-android)
